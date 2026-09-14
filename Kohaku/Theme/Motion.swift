//
//  Motion.swift
//  Kohaku
//
//  Design system — Motion (v0.2) §08
//  No .spring() animations. EaseInOut / EaseOut / bespoke cubic only.
//

import SwiftUI

enum KohakuMotion {
    /// 240ms easeInOut — small state changes, hovers
    static let fast: Animation = .easeInOut(duration: 0.24)

    /// 400ms easeOut — screen transitions (default)
    static let medium: Animation = .easeOut(duration: 0.4)

    /// 600ms easeInOut — modal presentation, reader open
    static let slow: Animation = .easeInOut(duration: 0.6)

    /// 900ms bespoke cubic — story cover reveal, chapter transitions
    /// The "dread" curve: slow start, gentle acceleration, patient end.
    static let dread: Animation = .timingCurve(0.3, 0, 0.2, 1, duration: 0.9)
}
