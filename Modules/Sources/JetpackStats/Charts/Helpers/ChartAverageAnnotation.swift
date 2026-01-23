import SwiftUI

struct ChartAverageAnnotation: View {
    let value: Int
    let formatter: any ValueFormatterProtocol

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Text(formatter.format(value: value, context: .compact))
            .font(.caption2.weight(.medium)).tracking(-0.1)
            .foregroundStyle(Color.secondary)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(
                colorScheme == .light ? Constants.Colors.background : Color(.opaqueSeparator).opacity(0.8)
            )
            .clipShape(.capsule)
            .padding(.leading, -5)
    }
}
