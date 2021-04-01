import SwiftUI

struct UnifiedPrologueBackgroundView: View {
    var body: some View {
        GeometryReader { content in
            let height = content.size.height
            let width = content.size.width
            let radius = min(height, width) * 0.16

            VStack {
                // This is a bit of a hack, but without this disabled ScrollView,
                // the position of circles would change depending on some traits changes.
                ScrollView {
                    CircledPathView(center: CGPoint(x: radius, y: -radius * 0.5),
                                    radius: radius,
                                    startAngle: 335,
                                    endAngle: 180,
                                    clockWise: false,
                                    color: Color(UIColor.muriel(name: .purple, .shade10)),
                                    lineWidth: 3.0)

                    CircledPathView(center: CGPoint(x: width + radius / 4, y: height - radius * 1.5),
                                    radius: radius,
                                    startAngle: 90,
                                    endAngle: 270,
                                    clockWise: false,
                                    color: Color(UIColor.muriel(name: .green, .shade10)),
                                    lineWidth: 3.0)

                    CircledPathView(center: CGPoint(x: 0, y: height - radius * 2),
                                    radius: radius,
                                    startAngle: 270,
                                    endAngle: 90,
                                    clockWise: false,
                                    color: Color(UIColor.muriel(name: .blue, .shade20)),
                                    lineWidth: 3.0)
                }
                .disabled(true)
            }
        }
    }
}

struct CircledPathView: View {
    let center: CGPoint
    let radius: CGFloat
    let startAngle: Double
    let endAngle: Double
    let clockWise: Bool
    let color: Color
    let lineWidth: CGFloat

    var body: some View {
        Path { path in
            path.addArc(center: center,
                        radius: radius,
                        startAngle: .degrees(startAngle),
                        endAngle: .degrees(endAngle),
                        clockwise: clockWise)
        }
        .stroke(color, lineWidth: lineWidth)

    }
}


struct Arc: Shape {
    let center: CGPoint
    let radius: CGFloat
    let startAngle: Double
    let endAngle: Double
    let clockwise: Bool

    func path(in rect: CGRect) -> Path {
        var p = Path()

        p.addArc(center: CGPoint(x: rect.origin.x + radius, y: rect.origin.y + radius), radius: radius, startAngle: .degrees(startAngle), endAngle: .degrees(endAngle), clockwise: clockwise)
        return p
    }
}
