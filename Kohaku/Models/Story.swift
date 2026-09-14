//
//  Story.swift
//  Kohaku
//
//  A tale in the Kohaku library. Now supports multi-chapter stories.
//

import Foundation

// MARK: - Story

struct Story: Identifiable, Hashable, Codable {
    let id: String                   // slug — matches cover asset name AND JSON filename
    let title: String
    let author: String
    let category: StoryCategory
    let collectionNumber: Int        // "Nº 03"
    let contentWarnings: [String]
    let excerpt: String              // 2-3 sentence hook shown on detail
    let chapters: [Chapter]
    let isPremium: Bool

    var coverAssetName: String { id }
    var formattedNumber: String { String(format: "Nº %02d", collectionNumber) }

    /// Total reading time = sum of chapter reading times.
    var readingTimeMinutes: Int {
        chapters.reduce(0) { $0 + $1.readingTimeMinutes }
    }

    var readingTimeLabel: String { "— \(readingTimeMinutes) min read —" }

    /// Sum of all body word counts.
    var wordCount: Int {
        chapters.reduce(0) { $0 + $1.wordCount }
    }
}

// MARK: - Chapter

struct Chapter: Identifiable, Hashable, Codable {
    let id: String                   // slug within the story, e.g. "chapter-one"
    let number: Int                  // 1, 2, 3
    let title: String                // "The Line" (does not include "Chapter N")
    let body: String                 // full markdown-style prose

    /// Roman numeral for display ("I", "II", "III").
    var romanNumeral: String {
        let romans = ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"]
        guard number >= 1, number <= romans.count else { return "\(number)" }
        return romans[number - 1]
    }

    /// Approximate word count based on whitespace split.
    var wordCount: Int {
        body.split { $0.isWhitespace }.count
    }

    /// Estimated reading time — 220 wpm.
    var readingTimeMinutes: Int {
        max(1, Int(ceil(Double(wordCount) / 220.0)))
    }
}

// MARK: - Category

enum StoryCategory: String, Codable, CaseIterable {
    case bodyHorror = "body horror"
    case cosmicHorror = "cosmic horror"
    case weird = "weird"

    var displayName: String {
        switch self {
        case .bodyHorror:   return "BODY HORROR"
        case .cosmicHorror: return "COSMIC HORROR"
        case .weird:        return "WEIRD"
        }
    }
}

// MARK: - Catalog entry

/// Minimal descriptor stored in `catalog.json` — points to individual story files.
struct CatalogEntry: Identifiable, Codable {
    let id: String              // matches Story.id and filename (without .json)
    let publishedAt: String     // ISO date string
    let isPremium: Bool
}

struct Catalog: Codable {
    let version: Int
    let stories: [CatalogEntry]
}
