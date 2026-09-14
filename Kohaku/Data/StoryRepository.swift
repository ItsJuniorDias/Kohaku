//
//  StoryRepository.swift
//  Kohaku
//
//  Story storage abstraction. Loads from bundled JSON at init.
//  Falls back to MockStories if catalog missing (dev safety).
//

import Foundation
import SwiftUI

@Observable
final class StoryRepository {
    private(set) var allStories: [Story]

    private(set) var libraryStoryIDs: Set<String> = []
    private(set) var finishedStoryIDs: Set<String> = []
    private(set) var progress: [String: Double] = [:]

    /// Per-chapter progress, keyed as "storyID#chapterID".
    private(set) var chapterProgress: [String: Double] = [:]

    // MARK: - Weekly rotation
    //
    // The ID of the premium story that is currently free. Recomputed on init
    // and via `refreshWeeklyRotation()` — call that when the scene reactivates
    // so a user who kept the app open across midnight UTC sees the new story
    // without a relaunch.
    private(set) var weeklyFreeStoryID: String?

    /// When the currently free story stops being free.
    private(set) var nextRotationDate: Date = WeeklyRotation.nextRotationDate()

    init() {
        do {
            self.allStories = try StoryLoader.loadAll()
            #if DEBUG
            print("✓ Kohaku: loaded \(allStories.count) stories from JSON")
            #endif
        } catch {
            #if DEBUG
            print("⚠️  Kohaku: falling back to MockStories — \(error)")
            #endif
            self.allStories = MockStories.all
        }
        refreshWeeklyRotation()
    }

    /// Recompute the free-of-the-week from the current clock. Cheap — safe
    /// to call every time the app comes to the foreground.
    func refreshWeeklyRotation() {
        let premiumIDs = allStories.filter { $0.isPremium }.map(\.id)
        self.weeklyFreeStoryID = WeeklyRotation.currentFreeStoryID(premiumIDs: premiumIDs)
        self.nextRotationDate = WeeklyRotation.nextRotationDate()
    }

    /// The story currently free by rotation, if any.
    var weeklyFreeStory: Story? {
        guard let id = weeklyFreeStoryID else { return nil }
        return allStories.first(where: { $0.id == id })
    }

    /// Central access-check: is this story readable without an active
    /// subscription? True for non-premium stories AND for the premium story
    /// currently featured by the weekly rotation.
    ///
    /// Note: this does NOT check the subscription itself — the subscription
    /// state lives in SubscriptionManager. Views combine the two.
    func isFreeToRead(_ story: Story) -> Bool {
        !story.isPremium || story.id == weeklyFreeStoryID
    }

    // MARK: - Library

    var library: [Story] {
        allStories.filter { libraryStoryIDs.contains($0.id) }
    }

    func addToLibrary(_ story: Story) {
        libraryStoryIDs.insert(story.id)
    }

    func removeFromLibrary(_ story: Story) {
        libraryStoryIDs.remove(story.id)
    }

    func isInLibrary(_ story: Story) -> Bool {
        libraryStoryIDs.contains(story.id)
    }

    // MARK: - Progress

    func markFinished(_ story: Story) {
        finishedStoryIDs.insert(story.id)
        progress[story.id] = 1.0
    }

    func setProgress(_ value: Double, for story: Story) {
        progress[story.id] = max(0, min(1, value))
        if value >= 1.0 {
            finishedStoryIDs.insert(story.id)
        }
    }

    func progressFor(_ story: Story) -> Double {
        progress[story.id] ?? 0
    }

    // MARK: - Chapter progress

    private func chapterKey(_ story: Story, _ chapter: Chapter) -> String {
        "\(story.id)#\(chapter.id)"
    }

    func setChapterProgress(_ value: Double, story: Story, chapter: Chapter) {
        chapterProgress[chapterKey(story, chapter)] = max(0, min(1, value))
        // Also update the aggregate story progress
        let chapterCount = Double(story.chapters.count)
        let cumulative = story.chapters.reduce(0.0) { acc, ch in
            acc + (chapterProgress[chapterKey(story, ch)] ?? 0)
        }
        setProgress(cumulative / chapterCount, for: story)
    }

    func chapterProgress(story: Story, chapter: Chapter) -> Double {
        chapterProgress[chapterKey(story, chapter)] ?? 0
    }

    func isChapterFinished(story: Story, chapter: Chapter) -> Bool {
        chapterProgress(story: story, chapter: chapter) >= 0.98
    }
}
