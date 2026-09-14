//
//  EyeShape.swift
//  Kohaku
//
//  Eye ornament — used at chapter openers, major story shifts.
//

import SwiftUI

struct EyeShape: View {
    var stroke: Color = .kohakuBone

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width * 0.7
            let h = geo.size.height * 0.55
            let cx = geo.size.width / 2
            let cy = geo.size.height / 2

            ZStack {
                // Almond outline — top curve
                Path { p in
                    p.move(to: CGPoint(x: cx - w/2, y: cy))
                    p.addCurve(
                        to: CGPoint(x: cx + w/2, y: cy),
                        control1: CGPoint(x: cx - w/4, y: cy - h/2),
                        control2: CGPoint(x: cx + w/4, y: cy - h/2)
                    )
                }
                .stroke(stroke, style: StrokeStyle(lineWidth: 1.5, lineCap: .round))

                // Almond outline — bottom curve
                Path { p in
                    p.move(to: CGPoint(x: cx - w/2, y: cy))
                    p.addCurve(
                        to: CGPoint(x: cx + w/2, y: cy),
                        control1: CGPoint(x: cx - w/4, y: cy + h/2),
                        control2: CGPoint(x: cx + w/4, y: cy + h/2)
                    )
                }
                .stroke(stroke, style: StrokeStyle(lineWidth: 1.5, lineCap: .round))

                // Iris
                Circle()
                    .stroke(stroke, lineWidth: 1)
                    .frame(width: h * 0.56, height: h * 0.56)

                // Pupil
                Circle()
                    .fill(stroke)
                    .frame(width: h * 0.2, height: h * 0.2)
            }
        }
    }
}

#Preview {
    ZStack {
        Color.kohakuVoid.ignoresSafeArea()
        EyeShape()
            .frame(width: 140, height: 80)
    }
}
