//
//  Story+Audio.swift
//  Kohaku
//
//  Resolve audio file URLs from the bundle. Audio lives at:
//    Kohaku/Resources/Audio/<story-id>/chapter-NN.mp3
//  and is bundled with the app (folder reference via filesystem-sync group).
//

import Foundation

extension Story {

    /// URL of the MP3 file for a given chapter, if it exists in the bundle.
    /// Returns nil when the file is missing — the UI should treat this as
    /// "audio unavailable for this chapter" rather than a fatal error.
    ///
    /// Files are bundled flat as `<story-id>-chapter-NN.mp3` because
    /// Xcode 16's filesystem-sync groups don't preserve subdirectory
    /// namespaces for resources — using story-id-prefixed filenames
    /// avoids collisions between different stories' chapter files.
    func audioURL(for chapter: Chapter) -> URL? {
        let filename = String(format: "%@-chapter-%02d", id, chapter.number)
        return Bundle.main.url(forResource: filename, withExtension: "mp3")
    }

    /// Whether audio is available for at least the first chapter — cheap
    /// check used by the UI to decide whether to show the "Listen" button
    /// on the story detail screen.
    var hasAudio: Bool {
        guard let first = chapters.first else { return false }
        return audioURL(for: first) != nil
    }

    /// URL of the looping motion video for this story's cover, if it
    /// exists in the bundle. Files are bundled flat as `<story-id>.mp4`
    /// in Resources/Videos/. IDs are already unique across stories so
    /// no prefix collision is possible.
    var coverVideoURL: URL? {
        Bundle.main.url(forResource: id, withExtension: "mp4")
    }

    /// Whether motion video is bundled for this story.
    var hasCoverVideo: Bool {
        coverVideoURL != nil
    }
}
