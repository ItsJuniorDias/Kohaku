//
//  KohakuCard.swift
//  Kohaku
//
//  Elevated surface. Ink fill + ash hairline border.
//  No shadows (see DS §07 — Elevation).
//

import SwiftUI

struct KohakuCard<Content: View>: View {
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        content()
            .background(Color.kohakuInk)
            .clipShape(RoundedRectangle(cornerRadius: KohakuRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: KohakuRadius.md)
                    .stroke(Color.kohakuAsh.opacity(0.4), lineWidth: 0.3)
            )
    }
}
