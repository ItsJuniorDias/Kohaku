//
//  AudioPlayerService.swift
//  Kohaku
//
//  Global audio playback state. One instance lives in the environment,
//  shared across every screen so the mini-player and the reader show
//  the same state.
//
//  Design decisions:
//
//  • AVAudioPlayer (not AVPlayer): our files are small local MP3s, no
//    streaming; AVAudioPlayer gives us cleaner rate/duration control.
//  • .playback category with .default mode: audio continues when the
//    screen locks, when other apps request audio (short-form), and
//    when the phone is on silent. Correct for an audiobook use case.
//  • The delegate hook auto-advances to the next chapter when a file
//    finishes naturally. Manual next/prev also work.
//  • A CADisplayLink drives currentTime updates only WHILE playing,
//    at display refresh rate. When paused, no updates fire — battery
//    friendly.
//  • Rate is capped to AVAudioPlayer's supported range 0.5…2.0. We
//    ship a discrete set of user-facing values.
//

import Foundation
import AVFoundation
import Combine
import MediaPlayer
import UIKit

@Observable
final class AudioPlayerService: NSObject {

    // MARK: - Public state (read-only from views)

    private(set) var currentStory: Story?
    private(set) var currentChapter: Chapter?
    private(set) var isPlaying: Bool = false
    private(set) var duration: TimeInterval = 0
    private(set) var currentTime: TimeInterval = 0

    /// User-facing playback speed. Use `setPlaybackRate(_:)` to update
    /// — direct assignment is permitted but clamping happens via the
    /// setter method to keep the didSet-free.
    private(set) var playbackRate: Float = 1.0

    /// Update playback speed. Clamps to AVAudioPlayer's 0.5…2.0 range,
    /// applies to the current player if any, and refreshes Now Playing.
    func setPlaybackRate(_ rate: Float) {
        let clamped = min(max(rate, 0.5), 2.0)
        playbackRate = clamped
        if let player, player.isPlaying {
            player.rate = clamped
        }
        updateNowPlaying()
    }

    /// Discrete speeds shown in the UI. 1.0 is the anchor.
    static let availableRates: [Float] = [0.75, 1.0, 1.25, 1.5, 2.0]

    // MARK: - Private

    @ObservationIgnored private var player: AVAudioPlayer?
    @ObservationIgnored private var displayLink: CADisplayLink?
    @ObservationIgnored private var didConfigureSession = false
    @ObservationIgnored private var didWireRemoteCommands = false

    // MARK: - Public API

    /// Start playback of a specific chapter. If it's already the current
    /// chapter, this just resumes; otherwise it loads the new file.
    func play(story: Story, chapter: Chapter) {
        if currentStory?.id == story.id && currentChapter?.id == chapter.id {
            resume()
            return
        }
        loadAndPlay(story: story, chapter: chapter)
    }

    /// Pause playback. Position is retained.
    func pause() {
        player?.pause()
        isPlaying = false
        stopDisplayLink()
        updateNowPlaying()
    }

    /// Resume from the current position. No-op if nothing is loaded.
    func resume() {
        guard let player else { return }
        configureAudioSessionIfNeeded()
        player.play()
        player.rate = playbackRate
        isPlaying = true
        startDisplayLink()
        updateNowPlaying()
    }

    /// Toggle play/pause on whatever is currently loaded.
    func togglePlayPause() {
        if isPlaying { pause() } else { resume() }
    }

    /// Fully stop and clear state. Used when the user hits "close" on
    /// the full player or when nothing is loaded anymore.
    func stop() {
        player?.stop()
        player = nil
        currentStory = nil
        currentChapter = nil
        isPlaying = false
        duration = 0
        currentTime = 0
        stopDisplayLink()
        clearNowPlaying()
    }

    /// Seek to an absolute time in seconds. Clamped to [0, duration].
    func seek(to time: TimeInterval) {
        guard let player else { return }
        let clamped = min(max(0, time), duration)
        player.currentTime = clamped
        currentTime = clamped
        updateNowPlaying()
    }

    /// Skip forward `seconds` (default 15). Never past the end.
    func skipForward(_ seconds: TimeInterval = 15) {
        seek(to: currentTime + seconds)
    }

    /// Skip backward `seconds` (default 15). Never before 0.
    func skipBackward(_ seconds: TimeInterval = 15) {
        seek(to: currentTime - seconds)
    }

    /// Go to the next chapter within the current story, if any.
    /// Returns true if it advanced.
    @discardableResult
    func playNextChapter() -> Bool {
        guard let story = currentStory, let ch = currentChapter else { return false }
        guard let next = nextChapter(after: ch, in: story) else { return false }
        loadAndPlay(story: story, chapter: next)
        return true
    }

    /// Go to the previous chapter within the current story, if any.
    /// Returns true if it moved.
    @discardableResult
    func playPreviousChapter() -> Bool {
        guard let story = currentStory, let ch = currentChapter else { return false }
        guard let prev = previousChapter(before: ch, in: story) else { return false }
        loadAndPlay(story: story, chapter: prev)
        return true
    }

    // MARK: - Loading

    private func loadAndPlay(story: Story, chapter: Chapter) {
        guard let url = story.audioURL(for: chapter) else {
            #if DEBUG
            print("⚠️  Kohaku: no audio for \(story.id) ch.\(chapter.number)")
            #endif
            return
        }
        configureAudioSessionIfNeeded()
        wireRemoteCommandsIfNeeded()

        do {
            let newPlayer = try AVAudioPlayer(contentsOf: url)
            newPlayer.delegate = self
            newPlayer.enableRate = true
            newPlayer.prepareToPlay()
            newPlayer.rate = playbackRate
            newPlayer.play()

            self.player = newPlayer
            self.currentStory = story
            self.currentChapter = chapter
            self.duration = newPlayer.duration
            self.currentTime = 0
            self.isPlaying = true

            startDisplayLink()
            updateNowPlaying()
        } catch {
            #if DEBUG
            print("⚠️  Kohaku: failed to load audio at \(url) — \(error)")
            #endif
        }
    }

    // MARK: - Chapter navigation helpers

    private func nextChapter(after chapter: Chapter, in story: Story) -> Chapter? {
        guard let idx = story.chapters.firstIndex(where: { $0.id == chapter.id }),
              idx + 1 < story.chapters.count
        else { return nil }
        return story.chapters[idx + 1]
    }

    private func previousChapter(before chapter: Chapter, in story: Story) -> Chapter? {
        guard let idx = story.chapters.firstIndex(where: { $0.id == chapter.id }),
              idx - 1 >= 0
        else { return nil }
        return story.chapters[idx - 1]
    }

    // MARK: - AVAudioSession

    private func configureAudioSessionIfNeeded() {
        guard !didConfigureSession else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            // .playback = plays even on silent switch, continues in background
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)
            didConfigureSession = true
        } catch {
            #if DEBUG
            print("⚠️  Kohaku: audio session setup failed — \(error)")
            #endif
        }
    }

    // MARK: - Display link (drives currentTime updates)

    private func startDisplayLink() {
        stopDisplayLink()
        let link = CADisplayLink(target: self, selector: #selector(tick))
        // 4 Hz is enough for a scrubber; anything higher wastes battery
        // for a use case where the UI updates smoothly at second-level.
        link.preferredFrameRateRange = CAFrameRateRange(minimum: 2, maximum: 4, preferred: 4)
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    private func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func tick() {
        guard let player, player.isPlaying else { return }
        currentTime = player.currentTime
    }

    // MARK: - Now Playing Info (lock screen + control center)

    private func wireRemoteCommandsIfNeeded() {
        guard !didWireRemoteCommands else { return }
        let center = MPRemoteCommandCenter.shared()

        center.playCommand.addTarget { [weak self] _ in
            self?.resume()
            return .success
        }
        center.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }
        center.togglePlayPauseCommand.addTarget { [weak self] _ in
            self?.togglePlayPause()
            return .success
        }
        center.skipForwardCommand.preferredIntervals = [15]
        center.skipForwardCommand.addTarget { [weak self] _ in
            self?.skipForward(15)
            return .success
        }
        center.skipBackwardCommand.preferredIntervals = [15]
        center.skipBackwardCommand.addTarget { [weak self] _ in
            self?.skipBackward(15)
            return .success
        }
        center.nextTrackCommand.addTarget { [weak self] _ in
            self?.playNextChapter() == true ? .success : .noSuchContent
        }
        center.previousTrackCommand.addTarget { [weak self] _ in
            self?.playPreviousChapter() == true ? .success : .noSuchContent
        }
        center.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let event = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            self?.seek(to: event.positionTime)
            return .success
        }
        didWireRemoteCommands = true
    }

    private func updateNowPlaying() {
        guard let story = currentStory, let chapter = currentChapter else {
            clearNowPlaying()
            return
        }
        var info: [String: Any] = [:]
        info[MPMediaItemPropertyTitle] = "Ch. \(chapter.number). \(chapter.title)"
        info[MPMediaItemPropertyArtist] = story.title
        info[MPMediaItemPropertyAlbumTitle] = "Kohaku"
        info[MPMediaItemPropertyPlaybackDuration] = duration
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? playbackRate : 0

        // Cover artwork from the app assets — the cover for each story
        // is `<story-id>` in Assets.xcassets.
        if let uiImage = UIImage(named: story.coverAssetName) {
            let artwork = MPMediaItemArtwork(boundsSize: uiImage.size) { _ in uiImage }
            info[MPMediaItemPropertyArtwork] = artwork
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func clearNowPlaying() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }
}

// MARK: - AVAudioPlayerDelegate

extension AudioPlayerService: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        guard flag else { return }
        // Natural end → auto-advance to next chapter, or stop if this
        // was the last one.
        if !playNextChapter() {
            isPlaying = false
            currentTime = duration
            stopDisplayLink()
            updateNowPlaying()
        }
    }
}
