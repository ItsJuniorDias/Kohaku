//
//  WeeklyRotation.swift
//  Kohaku
//
//  Weekly free-tale rotation. One premium story becomes free each week,
//  in a fixed shuffled order shared across all devices, cycling forever.
//
//  Design decisions:
//
//  • Client-side only, no backend. Every device computes the same answer.
//  • Anchor: Monday 2026-08-31 00:00 UTC (week 0). Chosen because it's the
//    Monday of Kohaku's launch week. Never change this — changing the
//    anchor rotates the whole schedule.
//  • Rotation happens Monday 00:00 UTC everywhere. Users in different
//    timezones see the switch at their local Monday morning or Sunday
//    evening, but every device shows the same story at the same UTC
//    instant.
//  • Order: `WeeklyRotation.rotationSeed` is used with a seeded PRNG
//    (SplitMix64) to shuffle the premium story IDs once. Same seed →
//    same order on every device. To reshuffle intentionally, change
//    the seed (and accept that every user's next-week story will change).
//  • Coverage: cycles through all premium IDs. After the last one, it
//    starts over. With 24 premium stories, the cycle repeats every ~5.5
//    months.
//  • The free-forever story (the-coil, isPremium=false) is not part of
//    the rotation — it's always free, doesn't need a slot.
//

import Foundation

// MARK: - Public API

enum WeeklyRotation {

    /// Monday 2026-08-31 00:00:00 UTC. Never change this.
    static let anchor: Date = {
        var comps = DateComponents()
        comps.year = 2026
        comps.month = 8
        comps.day = 31
        comps.hour = 0
        comps.minute = 0
        comps.second = 0
        comps.timeZone = TimeZone(identifier: "UTC")
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal.date(from: comps)!
    }()

    /// Seed used to shuffle the premium story order. Same seed → same
    /// order on every device forever. Do not change unless you accept
    /// rewriting every user's rotation.
    ///
    /// Value is arbitrary and permanent. If you ever change it, every
    /// user's rotation reshuffles at their next app launch — probably
    /// not what you want after ship.
    ///
    /// Must fit in UInt64 (16 hex digits max).
    static let rotationSeed: UInt64 = 0xC0FFEE_DEADBEEF_20

    /// The story ID that is free right now, or nil if the pool is empty.
    /// Callers should re-invoke this on app launch and on scene activation.
    static func currentFreeStoryID(
        premiumIDs: [String],
        now: Date = Date()
    ) -> String? {
        guard !premiumIDs.isEmpty else { return nil }
        let order = shuffledOrder(premiumIDs)
        let week = weekIndex(from: now)
        // Non-negative modulo: works even if the clock is somehow before the
        // anchor (shouldn't happen in production, but harmless).
        let idx = ((week % order.count) + order.count) % order.count
        return order[idx]
    }

    /// When the current free story stops being free and the next one takes
    /// over. Callers can compute a countdown from `now` to this Date.
    static func nextRotationDate(now: Date = Date()) -> Date {
        let week = weekIndex(from: now)
        return anchor.addingTimeInterval(TimeInterval(week + 1) * secondsPerWeek)
    }

    // MARK: - Internals

    private static let secondsPerWeek: TimeInterval = 7 * 24 * 60 * 60

    /// How many full weeks have elapsed since the anchor. Weeks before the
    /// anchor are negative; the mod in `currentFreeStoryID` wraps them.
    static func weekIndex(from now: Date) -> Int {
        let elapsed = now.timeIntervalSince(anchor)
        return Int(floor(elapsed / secondsPerWeek))
    }

    /// Deterministic shuffle of the given IDs. Sorts first (so the input's
    /// initial order doesn't affect the output) and then shuffles with a
    /// seeded PRNG.
    static func shuffledOrder(_ ids: [String]) -> [String] {
        var rng = SeededGenerator(seed: rotationSeed)
        return ids.sorted().shuffled(using: &rng)
    }
}

// MARK: - Seeded PRNG

/// SplitMix64. Not for crypto — used only to produce a stable shuffle from
/// a fixed seed. Portable across Swift versions and Apple hardware, which
/// is what we need. (Swift's `SystemRandomNumberGenerator` is not seedable,
/// and the docs do not guarantee cross-version determinism for its output.)
private struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        // Avoid state==0, which would return 0 forever.
        self.state = seed == 0 ? 0xDEAD_BEEF_CAFE_BABE : seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z &>> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z &>> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z &>> 31)
    }
}

// MARK: - Convenience

extension WeeklyRotation {
    /// Human-friendly countdown string (e.g. "2d 4h" or "3h 42m" or "58s").
    /// Used by the discovery card.
    static func timeRemainingLabel(until nextRotation: Date, now: Date = Date()) -> String {
        let remaining = max(0, nextRotation.timeIntervalSince(now))
        let days = Int(remaining) / 86400
        let hours = (Int(remaining) % 86400) / 3600
        let minutes = (Int(remaining) % 3600) / 60
        let seconds = Int(remaining) % 60

        if days > 0 { return "\(days)d \(hours)h" }
        if hours > 0 { return "\(hours)h \(minutes)m" }
        if minutes > 0 { return "\(minutes)m \(seconds)s" }
        return "\(seconds)s"
    }
}
