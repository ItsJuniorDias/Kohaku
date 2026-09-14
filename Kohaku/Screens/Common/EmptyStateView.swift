//
//  EmptyStateView.swift
//  Kohaku
//
//  Reusable empty state. Matter-of-fact copy per DS Voice §16.
//

import SwiftUI

struct EmptyStateView: View {
    let message: String

    var body: some View {
        VStack(spacing: KohakuSpacing.xl) {
            EmptyCocoonShape()
                .frame(width: 140, height: 140)
                .opacity(0.7)

            KohakuText(message, style: .bodyMedium, color: .kohakuAsh, alignment: .center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(KohakuSpacing.lg)
    }
}

#Preview {
    ZStack {
        Color.kohakuVoid.ignoresSafeArea()
        EmptyStateView(message: "Nothing here yet.")
    }
}
