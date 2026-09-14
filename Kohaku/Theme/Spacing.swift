//
//  Spacing.swift
//  Kohaku
//
//  Design system — Spacing scale (v0.2) §06
//  4pt base.
//

import CoreGraphics

enum KohakuSpacing {
    static let xxs:  CGFloat = 4
    static let xs:   CGFloat = 8
    static let sm:   CGFloat = 12
    static let md:   CGFloat = 16
    static let lg:   CGFloat = 24
    static let xl:   CGFloat = 32
    static let xxl:  CGFloat = 48
    static let xxxl: CGFloat = 72

    /// iPhone outer margin
    static let phoneMargin: CGFloat = 20
    /// iPad content max readable width
    static let iPadMaxWidth: CGFloat = 640
    /// iPad outer margin
    static let iPadMargin: CGFloat = 40
}

enum KohakuRadius {
    static let none: CGFloat = 0
    static let sm:   CGFloat = 2
    static let md:   CGFloat = 4   // default
    static let lg:   CGFloat = 8
}
