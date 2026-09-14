//
//  FontDebug.swift
//  Kohaku
//
//  Font loading + verification.
//
//  We use PROGRAMMATIC font registration via CTFontManagerRegisterGraphicsFont
//  instead of relying solely on Info.plist UIAppFonts. This is more robust —
//  especially with Xcode 16's PBXFileSystemSynchronizedRootGroup where
//  bundle-resource inclusion of subfolder files can be inconsistent.
//
//  Called in KohakuApp init() before any View reads Font.custom(...).
//

import UIKit
import SwiftUI
import CoreText

enum FontDebug {

    /// Font files to register — must exist somewhere in the app bundle.
    /// We search recursively so location (Resources/Fonts, root, etc.) doesn't matter.
    static let bundledFontFiles = [
        "BodoniModa-VariableFont",
        "EBGaramond-VariableFont",
        "EBGaramond-Italic-VariableFont",
    ]

    /// Expected PostScript names — verified after registration.
    static let expectedPostScriptNames = [
        "BodoniModa-Regular",
        "EBGaramond-Regular",
        "EBGaramond-Italic",
    ]

    /// Register all bundled fonts programmatically, then verify.
    /// Idempotent: safe to call multiple times (CoreText de-dupes).
    static func registerAndVerifyFonts() {
        registerBundledFonts()
        verifyBundledFonts()
    }

    // MARK: - Registration

    private static func registerBundledFonts() {
        for fileName in bundledFontFiles {
            registerFont(named: fileName, ext: "ttf")
        }
    }

    private static func registerFont(named name: String, ext: String) {
        // Try Bundle.main.url with different lookup strategies
        var fontURL: URL? = nil

        // 1. Direct lookup in bundle root
        if let url = Bundle.main.url(forResource: name, withExtension: ext) {
            fontURL = url
        }

        // 2. Search in Resources/Fonts subdirectory
        if fontURL == nil {
            if let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: "Resources/Fonts") {
                fontURL = url
            }
        }

        // 3. Search in Fonts subdirectory
        if fontURL == nil {
            if let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: "Fonts") {
                fontURL = url
            }
        }

        // 4. Deep recursive search (last resort)
        if fontURL == nil {
            fontURL = findFileRecursively(name: "\(name).\(ext)", in: Bundle.main.bundleURL)
        }

        guard let url = fontURL else {
            #if DEBUG
            print("  ❌ Font file not found in bundle: \(name).\(ext)")
            #endif
            return
        }

        guard let dataProvider = CGDataProvider(url: url as CFURL) else {
            #if DEBUG
            print("  ❌ Could not create data provider for: \(name).\(ext)")
            #endif
            return
        }

        guard let cgFont = CGFont(dataProvider) else {
            #if DEBUG
            print("  ❌ Could not create CGFont for: \(name).\(ext)")
            #endif
            return
        }

        var error: Unmanaged<CFError>?
        let success = CTFontManagerRegisterGraphicsFont(cgFont, &error)

        #if DEBUG
        if success {
            let psName = cgFont.postScriptName as String? ?? "(unknown)"
            print("  ✓ Registered \(name).\(ext) — PostScript: \(psName)")
        } else if let err = error?.takeUnretainedValue() {
            let description = CFErrorCopyDescription(err) as String? ?? "(unknown)"
            // "already registered" error is fine (idempotent behavior)
            if description.contains("already registered") {
                print("  ↺ \(name).\(ext) already registered")
            } else {
                print("  ⚠️  Could not register \(name).\(ext): \(description)")
            }
        }
        #endif
    }

    /// Recursively search bundle for a file. Slow but bulletproof.
    private static func findFileRecursively(name: String, in dir: URL) -> URL? {
        guard let enumerator = FileManager.default.enumerator(
            at: dir,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else { return nil }

        for case let url as URL in enumerator {
            if url.lastPathComponent == name {
                return url
            }
        }
        return nil
    }

    // MARK: - Verification

    private static func verifyBundledFonts() {
        #if DEBUG
        print("\n─── Kohaku Font Verification ───")

        for name in expectedPostScriptNames {
            if UIFont(name: name, size: 12) != nil {
                print("  ✓ \(name) loaded")
            } else {
                print("  ❌ \(name) NOT loaded")
            }
        }

        print("\n  Available custom font families (Bodoni Moda / EB Garamond):")
        let relevant = UIFont.familyNames
            .filter {
                let lower = $0.lowercased()
                return lower.contains("bodoni moda") || lower.contains("eb garamond")
            }
        for family in relevant {
            print("    Family: \(family)")
            for name in UIFont.fontNames(forFamilyName: family) {
                print("      → \(name)")
            }
        }
        if relevant.isEmpty {
            print("    (none — bundled fonts did not register)")
        }
        print("─────────────────────────────────\n")
        #endif
    }
}
