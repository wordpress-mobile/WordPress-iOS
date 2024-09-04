import SwiftUI

struct UnifiedPrologueBackgroundView: View {
    var body: some View {
        GeometryReader { content in
            let height = content.size.height
            let width = content.size.width
            let radius = min(height, width) * 0.16

            let purpleCircleColor = Color(UIColor(light: AppColor.purple(.shade10), dark: AppColor.purple(.shade70)))
            let greenCircleColor = Color(UIColor(light: AppColor.celadon(.shade5), dark: AppColor.celadon(.shade70)))
            let blueCircleColor = Color(UIColor(light: AppColor.blue(.shade20), dark: AppColor.blue(.shade80)))
            let circleOpacity: Double = 0.8

            VStack {
                // This is a bit of a hack, but without this disabled ScrollView,
                // the position of circles would change depending on some traits changes.
                ScrollView {
                    CircledPathView(center: CGPoint(x: radius, y: -radius * 0.5),
                                    radius: radius,
                                    startAngle: 335,
                                    endAngle: 180,
                                    clockWise: false,
                                    color: purpleCircleColor,
                                    lineWidth: 3.0)
                        .opacity(circleOpacity)

                    CircledPathView(center: CGPoint(x: width + radius / 4, y: height - radius * 1.5),
                                    radius: radius,
                                    startAngle: 90,
                                    endAngle: 270,
                                    clockWise: false,
                                    color: greenCircleColor,
                                    lineWidth: 3.0)
                        .opacity(circleOpacity)

                    CircledPathView(center: CGPoint(x: 0, y: height - radius * 2),
                                    radius: radius,
                                    startAngle: 270,
                                    endAngle: 90,
                                    clockWise: false,
                                    color: blueCircleColor,
                                    lineWidth: 3.0)
                        .opacity(circleOpacity)
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
