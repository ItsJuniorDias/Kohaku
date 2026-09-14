//
//  Colors.swift
//  Kohaku
//
//  Design system — Color tokens (v0.2)
//  Monochrome palette: void, ink, bone, ash, pallor
//  No accent colors. See Kohaku-DesignSystem.pdf §04.
//

import SwiftUI

extension Color {
    /// Primary background. ~70% of every screen.
    /// Near-black with a warm undertone. Never #000000.
    static let kohakuVoid = Color(red: 0x0A / 255, green: 0x09 / 255, blue: 0x08 / 255)

    /// Elevated surfaces — cards, sheets.
    /// Barely distinguishable from void; that's the point.
    static let kohakuInk = Color(red: 0x14 / 255, green: 0x11 / 255, blue: 0x10 / 255)

    /// Primary text, primary CTAs, brand marks.
    /// Off-white the color of old paper. Never #FFFFFF.
    static let kohakuBone = Color(red: 0xED / 255, green: 0xE6 / 255, blue: 0xD6 / 255)

    /// Secondary text, ornaments, hairline borders, muted marks.
    static let kohakuAsh = Color(red: 0x7A / 255, green: 0x72 / 255, blue: 0x67 / 255)

    /// Tertiary text, muted metadata, disabled states.
    static let kohakuPallor = Color(red: 0xB8 / 255, green: 0xB0 / 255, blue: 0xA0 / 255)
}
