//
//  AppLinks.swift
//  Kohaku
//
//  External URLs used across the app.
//
//  Both legal pages are published as public Notion pages (marked-garage-d75
//  workspace). Apple Guideline 3.1.2(a) requires that any auto-renewing
//  subscription paywall display links to BOTH Terms of Use (EULA) and
//  Privacy Policy — missing either is an automatic App Store rejection.
//

import Foundation

enum AppLinks {

    /// Privacy Policy — shown on the paywall and in Settings > About.
    static let privacyPolicy = URL(string: "https://marked-garage-d75.notion.site/Kohaku-Privacy-Policy-EULA-3cb2f13e5f7d8097b3fdc65486fe73c9")!

    /// Terms of Use / EULA — shown on the paywall and in Settings > About.
    ///
    /// Note: Apple also accepts the standard EULA at
    /// https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
    /// but we ship our own.
    static let termsOfUse = URL(string: "https://marked-garage-d75.notion.site/Kohaku-Terms-of-use-Support-3cb2f13e5f7d80fda44fe33730da22d1")!

    /// Support / contact page — used in Settings > About.
    /// Currently points to the same page as terms (which has Support section).
    static let support: URL? = URL(string: "https://marked-garage-d75.notion.site/Kohaku-Terms-of-use-Support-3cb2f13e5f7d80fda44fe33730da22d1")
}
