//
//  EmptyCocoonShape.swift
//  Kohaku
//
//  Empty state illustration — the empty cocoon.
//  Shown when a section has no content.
//

import SwiftUI

struct EmptyCocoonShape: View {
    var stroke: Color = .kohakuAsh

    var body: some View {
        GeometryReader { geo in
            let cx = geo.size.width / 2
            let cy = geo.size.height / 2
            let w = geo.size.width * 0.4
            let h = geo.size.height * 0.6

            ZStack {
                // Cocoon body — bottom rounded
                Path { p in
                    p.move(to: CGPoint(x: cx - w/2, y: cy))
                    p.addCurve(
                        to: CGPoint(x: cx + w/2, y: cy),
                        control1: CGPoint(x: cx - w/2, y: cy + h/2),
                        control2: CGPoint(x: cx + w/2, y: cy + h/2)
                    )
                }
                .stroke(stroke, style: StrokeStyle(lineWidth: 1, lineCap: .round))

                // Left top open
                Path { p in
                    p.move(to: CGPoint(x: cx - w/2, y: cy))
                    p.addCurve(
                        to: CGPoint(x: cx - w/8, y: cy - h/2 - 5),
                        control1: CGPoint(x: cx - w/2 - 5, y: cy - h/3),
                        control2: CGPoint(x: cx - w/4, y: cy - h/2)
                    )
                }
                .stroke(stroke, style: StrokeStyle(lineWidth: 1, lineCap: .round))

                // Right top open
                Path { p in
                    p.move(to: CGPoint(x: cx + w/2, y: cy))
                    p.addCurve(
                        to: CGPoint(x: cx + w/8, y: cy - h/2 - 5),
                        control1: CGPoint(x: cx + w/2 + 5, y: cy - h/3),
                        control2: CGPoint(x: cx + w/4, y: cy - h/2)
                    )
                }
                .stroke(stroke, style: StrokeStyle(lineWidth: 1, lineCap: .round))

                // Interior hatching
                ForEach(-4...4, id: \.self) { i in
                    Path { p in
                        let offset = CGFloat(i) * 6
                        p.move(to: CGPoint(x: cx - w/3, y: cy - offset))
                        p.addLine(to: CGPoint(x: cx + w/3, y: cy - offset))
                    }
                    .stroke(Color.kohakuInk, lineWidth: 0.3)
                }
            }
        }
    }
}

#Preview {
    ZStack {
        Color.kohakuVoid.ignoresSafeArea()
        EmptyCocoonShape()
            .frame(width: 180, height: 180)
    }
}
