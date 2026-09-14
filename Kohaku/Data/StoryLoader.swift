//
//  StoryLoader.swift
//  Kohaku
//
//  Loads the Kohaku catalog and individual stories from bundled JSON files.
//
//  Files are located in Resources/Stories/ of the app bundle:
//    - catalog.json        (index of all stories)
//    - <story-id>.json     (one file per story)
//
//  Later, this can be swapped with a remote fetcher (URL session) without
//  touching the rest of the app.
//

import Foundation

enum StoryLoader {

    // MARK: - Errors

    enum LoaderError: Error, CustomStringConvertible {
        case catalogMissing
        case storyMissing(id: String)
        case decodingFailed(id: String, underlying: Error)

        var description: String {
            switch self {
            case .catalogMissing:
                return "catalog.json not found in bundle Resources/Stories/"
            case .storyMissing(let id):
                return "\(id).json not found in bundle Resources/Stories/"
            case .decodingFailed(let id, let err):
                return "failed to decode \(id).json — \(err)"
            }
        }
    }

    // MARK: - Public API

    /// Load the master catalog and all stories referenced by it.
    /// Stories that fail to decode are skipped with a debug log; the load
    /// does not fail overall unless the catalog itself is missing.
    static func loadAll() throws -> [Story] {
        let catalog = try loadCatalog()

        var stories: [Story] = []
        for entry in catalog.stories {
            do {
                let story = try loadStory(id: entry.id)
                stories.append(story)
            } catch {
                #if DEBUG
                print("⚠️  Kohaku: could not load story '\(entry.id)': \(error)")
                #endif
            }
        }
        return stories
    }

    /// Load the catalog index only.
    static func loadCatalog() throws -> Catalog {
        guard let url = Bundle.main.url(
            forResource: "catalog",
            withExtension: "json",
            subdirectory: "Stories"
        ) ?? Bundle.main.url(
            forResource: "catalog",
            withExtension: "json"
        ) else {
            throw LoaderError.catalogMissing
        }

        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(Catalog.self, from: data)
    }

    /// Load a single story by id.
    static func loadStory(id: String) throws -> Story {
        guard let url = Bundle.main.url(
            forResource: id,
            withExtension: "json",
            subdirectory: "Stories"
        ) ?? Bundle.main.url(
            forResource: id,
            withExtension: "json"
        ) else {
            throw LoaderError.storyMissing(id: id)
        }

        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(Story.self, from: data)
        } catch let error {
            throw LoaderError.decodingFailed(id: id, underlying: error)
        }
    }
}
