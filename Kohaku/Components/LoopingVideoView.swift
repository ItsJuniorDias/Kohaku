//
//  LoopingVideoView.swift
//  Kohaku
//
//  A looping, silent, cross-faded video view. Shows a static Image
//  first (instant), then fades to the video once its first frame is
//  ready. Used for animated story covers on Discover and StoryDetail.
//
//  Design decisions:
//
//  • AVPlayerLooper is Apple's supported way to loop with zero gap.
//    Manual "listen for end + seek to zero" always has a black frame
//    flash between loops.
//
//  • AVAudioSession.ambient category: our videos are silent, but if
//    the user is listening to a narration OR to their own music from
//    another app, this video's audio track (even empty) must not
//    interrupt. `.ambient` = "we mix, we don't take over".
//
//  • Auto pause when off-screen: SwiftUI's `.onDisappear` handles
//    this. Otherwise videos keep decoding when nav pushes to a new
//    screen, wasting battery.
//
//  • Cross-fade timing: the video's ready-state observer is what
//    triggers the fade. If the video never loads (missing file, bad
//    codec, disk error), we simply keep showing the still image
//    forever — no error state, no jump.
//

import SwiftUI
import AVFoundation
import Combine

struct LoopingVideoView: View {
    let videoURL: URL
    let placeholderImageName: String
    /// Duration of the cross-fade from placeholder → video (seconds).
    var crossFadeDuration: Double = 0.5

    @State private var isReady: Bool = false

    var body: some View {
        ZStack {
            // Placeholder — always in the layer stack, faded out when
            // the video is ready. Kept mounted (not conditionally
            // removed) so the layout doesn't shift during transition.
            Image(placeholderImageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .opacity(isReady ? 0 : 1)
                .animation(.easeInOut(duration: crossFadeDuration), value: isReady)

            LoopingPlayerLayerView(
                videoURL: videoURL,
                onReady: {
                    // Small deferral so the first frame is definitely
                    // presented before we start fading the placeholder.
                    // Without this the cross-fade can start on a black
                    // frame from the still-warming decoder.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        isReady = true
                    }
                }
            )
            .opacity(isReady ? 1 : 0)
            .animation(.easeInOut(duration: crossFadeDuration), value: isReady)
        }
        .clipped()
    }
}

// MARK: - UIViewRepresentable backing

/// UIView wrapper hosting an AVPlayerLayer. We reach through UIKit here
/// because SwiftUI's `VideoPlayer` shows player controls and doesn't
/// expose AVPlayerLooper; we need bare, controlless, gap-free playback.
private struct LoopingPlayerLayerView: UIViewRepresentable {
    let videoURL: URL
    let onReady: () -> Void

    func makeUIView(context: Context) -> LoopingPlayerUIView {
        let view = LoopingPlayerUIView(url: videoURL, onReady: onReady)
        return view
    }

    func updateUIView(_ uiView: LoopingPlayerUIView, context: Context) {
        // If the URL changed (rare — usually one view per story), swap
        // players. Comparing string form is safest across URL variants.
        if uiView.currentURL?.absoluteString != videoURL.absoluteString {
            uiView.reload(url: videoURL, onReady: onReady)
        }
    }

    static func dismantleUIView(_ uiView: LoopingPlayerUIView, coordinator: ()) {
        uiView.teardown()
    }
}

/// The actual UIView. Owns the AVPlayer + AVPlayerLooper + KVO observer
/// for the ready state. Handles setup, teardown, and pause-on-hide.
final class LoopingPlayerUIView: UIView {
    private var player: AVQueuePlayer?
    private var looper: AVPlayerLooper?
    private var readyObservation: NSKeyValueObservation?
    private var didFireReady = false

    private(set) var currentURL: URL?

    override class var layerClass: AnyClass { AVPlayerLayer.self }
    private var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }

    init(url: URL, onReady: @escaping () -> Void) {
        super.init(frame: .zero)
        backgroundColor = .clear
        configureAudioSessionIfNeeded()
        setup(url: url, onReady: onReady)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    // MARK: - Setup / teardown

    private func setup(url: URL, onReady: @escaping () -> Void) {
        currentURL = url

        let asset = AVURLAsset(url: url)
        let item = AVPlayerItem(asset: asset)
        // Force audio off at the item level — belt and suspenders with
        // the ambient audio session. Ensures we never contribute audio
        // even if a file accidentally has an audio track.
        item.audioMix = silentAudioMix(for: asset)

        let queuePlayer = AVQueuePlayer(playerItem: item)
        queuePlayer.isMuted = true
        queuePlayer.actionAtItemEnd = .advance  // AVPlayerLooper drives this
        queuePlayer.allowsExternalPlayback = false
        queuePlayer.preventsDisplaySleepDuringVideoPlayback = false

        // The looper enqueues copies of `item` behind the current one so
        // playback is seamless. Without it we'd get a visible black flash
        // between loops.
        looper = AVPlayerLooper(player: queuePlayer, templateItem: item)

        playerLayer.player = queuePlayer
        playerLayer.videoGravity = .resizeAspectFill

        player = queuePlayer

        // Fire onReady when the first frame is available for display.
        // `isReadyForDisplay` on the layer flips true when the decoder
        // has produced its first frame — this is the exact moment the
        // cross-fade should start.
        readyObservation = playerLayer.observe(\.isReadyForDisplay, options: [.new]) {
            [weak self] layer, _ in
            guard let self, !self.didFireReady, layer.isReadyForDisplay else { return }
            self.didFireReady = true
            DispatchQueue.main.async {
                onReady()
            }
        }

        queuePlayer.play()
    }

    func reload(url: URL, onReady: @escaping () -> Void) {
        teardown()
        didFireReady = false
        setup(url: url, onReady: onReady)
    }

    func teardown() {
        readyObservation?.invalidate()
        readyObservation = nil
        player?.pause()
        looper = nil
        player = nil
        playerLayer.player = nil
        currentURL = nil
    }

    // MARK: - Pause when off-screen

    // `willMove(toWindow:)` fires when the view's window changes — when
    // SwiftUI removes the view (nav pop, tab switch), window becomes nil.
    // We pause here so decoding stops immediately. When the view comes
    // back on-screen, `didMoveToWindow` starts playback again.
    override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        if newWindow == nil {
            player?.pause()
        }
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil {
            player?.play()
        }
    }

    // MARK: - Helpers

    /// Builds a silent AVAudioMix. Even if a video's file has an audio
    /// track, we zero its volume before it can reach the mixer.
    private func silentAudioMix(for asset: AVAsset) -> AVAudioMix? {
        let tracks = asset.tracks(withMediaType: .audio)
        guard !tracks.isEmpty else { return nil }
        let mix = AVMutableAudioMix()
        mix.inputParameters = tracks.map { track in
            let params = AVMutableAudioMixInputParameters(track: track)
            params.setVolume(0, at: .zero)
            return params
        }
        return mix
    }

    /// Set the audio session to `.ambient` once per app lifecycle. This
    /// category means "we may play audio but we mix with others; the
    /// silent switch silences us". It's what we want for a decorative
    /// looping video: never interrupts narration, never interrupts the
    /// user's Spotify.
    ///
    /// Note: this overrides AudioPlayerService's `.playback` category
    /// only if it hasn't been set yet. Once the user starts narration,
    /// AudioPlayerService switches to `.playback` (which allows silent-
    /// switch bypass and background) and stays there. Our silent video
    /// is fine to coexist in either mode.
    private func configureAudioSessionIfNeeded() {
        let session = AVAudioSession.sharedInstance()
        // If someone already configured it (typically AudioPlayerService),
        // leave their category alone.
        if session.category == .playback { return }
        do {
            try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            #if DEBUG
            print("⚠️  Kohaku: LoopingVideoView audio session setup failed — \(error)")
            #endif
        }
    }
}
