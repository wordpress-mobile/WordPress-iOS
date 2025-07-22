import SwiftUI

struct TopListItemBarBackground: View {
    let value: Int
    let maxValue: Int
    let barColor: Color

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(barColor.opacity(colorScheme == .light ? 0.09 : 0.25))
                    .frame(width: barWidth(in: geometry))
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: value)
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
