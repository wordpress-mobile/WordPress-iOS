import SwiftUI

struct ChartAverageAnnotation: View {
    let value: Int
    let formatter: StatsValueFormatter

    var body: some View {
        Text(formatter.format(value: value, context: .compact))
            .font(.caption2.weight(.medium)).tracking(-0.1)
            .foregroundStyle(Color.secondary)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(Constants.Colors.background)
            .clipShape(.capsule)
            .padding(.leading, -5)
    }
}
