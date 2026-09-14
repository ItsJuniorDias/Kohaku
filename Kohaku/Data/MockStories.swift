//
//  MockStories.swift
//  Kohaku
//
//  Emergency fallback if the JSON catalog cannot be loaded.
//  Production data lives in Resources/Stories/*.json — see StoryLoader.
//

import Foundation

enum MockStories {
    static let all: [Story] = [
        Story(
            id: "the-coil",
            title: "The Coil",
            author: "Alexandre Dias",
            category: .bodyHorror,
            collectionNumber: 1,
            contentWarnings: ["Body horror"],
            excerpt: "She noticed the mark on the seventh morning.",
            chapters: [
                Chapter(
                    id: "chapter-one",
                    number: 1,
                    title: "The Mark",
                    body: "Fallback content — JSON catalog failed to load."
                )
            ],
            isPremium: false
        )
    ]
}
