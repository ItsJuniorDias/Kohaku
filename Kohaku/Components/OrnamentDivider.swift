//
//  OrnamentDivider.swift
//  Kohaku
//
//  Divisor ornamental (DS §12).
//  Duas variantes:
//   - full: três pontos + linhas hatched (entre seções de UI)
//   - minimal: só três pontos (entre parágrafos no reader)
//

import SwiftUI

struct OrnamentDivider: View {
    enum Style {
        case full     // With hatched extensions
        case minimal  // Just three dots
    }

    let style: Style
    var color: Color = .kohakuAsh

    init(style: Style = .full, color: Color = .kohakuAsh) {
        self.style = style
        self.color = color
    }

    var body: some View {
        switch style {
        case .minimal:
            HStack(spacing: KohakuSpacing.sm) {
                Circle().fill(color).frame(width: 3, height: 3)
                Circle().fill(color).frame(width: 3, height: 3)
                Circle().fill(color).frame(width: 3, height: 3)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, KohakuSpacing.sm)

        case .full:
            GeometryReader { geo in
                let mid = geo.size.width / 2
                let cy: CGFloat = 10

                ZStack {
                    // Center dot (larger)
                    Circle()
                        .fill(color)
                        .frame(width: 3, height: 3)
                        .position(x: mid, y: cy)

                    // Side dots
                    Circle()
                        .fill(color)
                        .frame(width: 1.6, height: 1.6)
                        .position(x: mid - 12, y: cy)
                    Circle()
                        .fill(color)
                        .frame(width: 1.6, height: 1.6)
                        .position(x: mid + 12, y: cy)

                    // Hatched extensions
                    Path { p in
                        // left
                        p.move(to: CGPoint(x: mid - 22, y: cy))
                        p.addLine(to: CGPoint(x: 20, y: cy))
                        // right
                        p.move(to: CGPoint(x: mid + 22, y: cy))
                        p.addLine(to: CGPoint(x: geo.size.width - 20, y: cy))
                    }
                    .stroke(color, lineWidth: 0.5)

                    // Small tick marks along the lines
                    ForEach(0..<3, id: \.self) { i in
                        let fraction = CGFloat(i) / 3.0
                        let leftX = mid - 22 - fraction * (mid - 42)
                        let rightX = mid + 22 + fraction * (mid - 42)

                        Path { p in
                            p.move(to: CGPoint(x: leftX, y: cy - 2))
                            p.addLine(to: CGPoint(x: leftX, y: cy + 2))
                            p.move(to: CGPoint(x: rightX, y: cy - 2))
                            p.addLine(to: CGPoint(x: rightX, y: cy + 2))
                        }
                        .stroke(color, lineWidth: 0.5)
                    }
                }
            }
            .frame(height: 20)
        }
    }
}

#Preview {
    ZStack {
        Color.kohakuVoid.ignoresSafeArea()
        VStack(spacing: KohakuSpacing.xl) {
            OrnamentDivider(style: .full)
            OrnamentDivider(style: .minimal)
        }
        .padding(KohakuSpacing.lg)
    }
}
