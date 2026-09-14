//
//  Typography.swift
//  Kohaku
//
//  Design system — Typography (v0.2)
//
//  FONTS
//  -----
//  Uses Bodoni Moda (display) + EB Garamond (body), both bundled as
//  Variable Fonts from Google Fonts (SIL Open Font License).
//
//  Bundled files in Resources/Fonts/:
//    - BodoniModa-VariableFont.ttf       (opsz + wght axes)
//    - EBGaramond-VariableFont.ttf       (wght axis)
//    - EBGaramond-Italic-VariableFont.ttf (wght axis)
//
//  PostScript names used by .custom(name:size:):
//    - BodoniModa-Regular
//    - EBGaramond-Regular
//    - EBGaramond-Italic
//
//  Weight (Bold vs Regular) is applied via .fontWeight() modifier,
//  which works with variable fonts on iOS 16+.
//

import SwiftUI

// MARK: - Font PostScript name constants
// Match the internal PostScript names of the bundled TTFs.
// If you replace the fonts, verify with:
//   fc-scan --format "%{postscriptname}\n" fontfile.ttf
// or on macOS: system_profiler SPFontsDataType | grep -A 3 "Bodoni Moda"

enum KohakuFontName {
    static let bodoniModa = "BodoniModa-Regular"
    static let ebGaramond = "EBGaramond-Regular"
    static let ebGaramondItalic = "EBGaramond-Italic"
}

// MARK: - Font families

enum KohakuFontFamily {
    /// Display font — Bodoni Moda variable font.
    /// The weight parameter is applied via a Font modifier by the caller.
    static func display(size: CGFloat) -> Font {
        .custom(KohakuFontName.bodoniModa, size: size)
    }

    /// Body font — EB Garamond variable font.
    static func body(size: CGFloat, italic: Bool = false) -> Font {
        .custom(italic ? KohakuFontName.ebGaramondItalic : KohakuFontName.ebGaramond, size: size)
    }

    /// Monospaced label font — Courier (system monospaced fallback).
    static func label(size: CGFloat) -> Font {
        .system(size: size, weight: .regular, design: .monospaced)
    }
}

// MARK: - Text Style tokens

enum KohakuTextStyle {
    case displayHero     // Bodoni Bold 40/44 — Story titles on cover screens
    case displayLarge    // Bodoni Bold 28/34 — Chapter titles
    case displayMedium   // Bodoni Bold 22/28 — Screen titles
    case displaySmall    // Bodoni Bold 17/22 — Card titles, section headers

    case bodyLarge       // EB Garamond 18/28 — Reader body default
    case bodyMedium      // EB Garamond 14/22 — Body text, descriptions
    case bodySmall       // EB Garamond 12/18 — Content warnings, metadata

    case quote           // EB Garamond Italic 14/22 — Pull quotes
    case caption         // EB Garamond Italic 10/14 — Image captions
    case label           // Courier 10pt uppercased — System labels

    var font: Font {
        switch self {
        case .displayHero:   return KohakuFontFamily.display(size: 48)
        case .displayLarge:  return KohakuFontFamily.display(size: 34)
        case .displayMedium: return KohakuFontFamily.display(size: 26)
        case .displaySmall:  return KohakuFontFamily.display(size: 20)
        case .bodyLarge:     return KohakuFontFamily.body(size: 20)
        case .bodyMedium:    return KohakuFontFamily.body(size: 16)
        case .bodySmall:     return KohakuFontFamily.body(size: 13)
        case .quote:         return KohakuFontFamily.body(size: 17, italic: true)
        case .caption:       return KohakuFontFamily.body(size: 12, italic: true)
        case .label:         return KohakuFontFamily.label(size: 11)
        }
    }

    /// Weight applied on top of the font.
    /// Variable fonts (Bodoni Moda, EB Garamond) respect this via SwiftUI.
    var weight: Font.Weight {
        switch self {
        case .displayHero, .displayLarge, .displayMedium, .displaySmall:
            return .bold      // Displays are bold
        case .bodySmall:
            return .regular
        case .bodyLarge, .bodyMedium, .quote, .caption, .label:
            return .regular
        }
    }

    /// Leading (line height) as an addition to font size, per DS spec.
    var lineSpacingAdjustment: CGFloat {
        switch self {
        case .displayHero:   return 5    // 48 → 53
        case .displayLarge:  return 7    // 34 → 41
        case .displayMedium: return 7    // 26 → 33
        case .displaySmall:  return 6    // 20 → 26
        case .bodyLarge:     return 11   // 20 → 31 (~1.55x for reader)
        case .bodyMedium:    return 9    // 16 → 25
        case .bodySmall:     return 7    // 13 → 20
        case .quote:         return 9    // 17 → 26
        case .caption:       return 5
        case .label:         return 5
        }
    }

    /// Default color for this style (overridable per instance).
    var defaultColor: Color {
        switch self {
        case .caption, .label, .bodySmall: return .kohakuAsh
        default: return .kohakuBone
        }
    }

    /// Labels are letterspaced.
    var tracking: CGFloat {
        switch self {
        case .label: return 1.5
        default:     return 0
        }
    }

    /// Labels are uppercased by default.
    var uppercased: Bool {
        switch self {
        case .label: return true
        default:     return false
        }
    }
}
