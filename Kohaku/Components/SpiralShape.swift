//
//  SpiralShape.swift
//  Kohaku
//
//  The spiral — Kohaku's central motif. Uzumaki-inspired.
//  Used sparingly: story endings, brand moments, empty states.
//

import SwiftUI

struct SpiralShape: Shape {
    var turns: Double = 5.5
    var steps: Int = 300

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let center = CGPoint(x: rect.midX, y: rect.midY)
        let maxRadius = min(rect.width, rect.height) / 2 - 4

        path.move(to: center)

        for i in 1...steps {
            let t = Double(i) / Double(steps)
            let angle = t * turns * 2 * .pi
            let radius = maxRadius * t
            let x = center.x + radius * cos(angle)
            let y = center.y + radius * sin(angle)
            path.addLine(to: CGPoint(x: x, y: y))
        }

        return path
    }
}

/// Composed Kohaku glyph — spiral inside ring, radial marks.
/// Used as brand mark, launch screen, About page.
struct KohakuGlyph: View {
    var stroke: Color = .kohakuBone
    var accent: Color = .kohakuAsh

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width/2, y: geo.size.height/2)

            ZStack {
                // Spiral
                SpiralShape(turns: 5.5)
                    .stroke(stroke, style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                    .frame(width: size * 0.56, height: size * 0.56)

                // Outer ring
                Circle()
                    .stroke(stroke, lineWidth: 2)
                    .frame(width: size * 0.84, height: size * 0.84)

                // Radial marks
                ForEach(0..<12, id: \.self) { i in
                    let angle = Double(i) / 12 * 2 * .pi
                    let rInner = size * 0.42
                    let rOuter = size * 0.45
                    Path { p in
                        p.move(to: CGPoint(
                            x: center.x + rInner * cos(angle),
                            y: center.y + rInner * sin(angle)
                        ))
                        p.addLine(to: CGPoint(
                            x: center.x + rOuter * cos(angle),
                            y: center.y + rOuter * sin(angle)
                        ))
                    }
                    .stroke(accent, lineWidth: 0.5)
                }
            }
        }
    }
}

#Preview {
    ZStack {
        Color.kohakuVoid.ignoresSafeArea()
        KohakuGlyph()
            .frame(width: 200, height: 200)
    }
}
