import SwiftUI

struct TopListItemBarBackground: View {
    let value: Int
    let maxValue: Int
    let barColor: Color

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                LinearGradient(
                    colors: [
                        barColor.opacity(colorScheme == .light ? 0.06 : 0.22),
                        barColor.opacity(colorScheme == .light ? 0.12 : 0.35),
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .mask(
                    HStack(spacing: 0) {
                        RoundedRectangle(cornerRadius: Constants.step1)
                            .frame(width: max(8, barWidth(in: geometry)))
                        Spacer(minLength: 0)
                    }
                )
                Spacer(minLength: 0)
            }
        }
    }

    private func barWidth(in geometry: GeometryProxy) -> CGFloat {
        guard maxValue > 0 else {
            return 0
        }
        let value = geometry.size.width * CGFloat(value) / CGFloat(maxValue)
        return max(0, value)
    }
}
