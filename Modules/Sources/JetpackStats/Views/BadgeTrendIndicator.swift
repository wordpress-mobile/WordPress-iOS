import SwiftUI

struct BadgeTrendIndicator: View {
    let trend: TrendViewModel

    init(trend: TrendViewModel) {
        self.trend = trend
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: trend.systemImage)
                .font(.caption2.weight(.semibold))
                .scaleEffect(x: 0.9, y: 0.9)
            Text(trend.formattedPercentage)
                .font(.system(.caption, design: .rounded, weight: .semibold)).tracking(-0.25)
        }
        .foregroundColor(trend.sentiment.foregroundColor)
        .padding(.horizontal, 7)
        .padding(.vertical, 6)
        .background(trend.sentiment.backgroundColor)
        .cornerRadius(6)
        .animation(.spring, value: trend.percentage)
    }
}

#Preview("Change Indicators") {
    VStack(spacing: 20) {
        Text("Examples").font(.headline)
        // 15% increase in views - positive sentiment
        BadgeTrendIndicator(trend: TrendViewModel(currentValue: 115, previousValue: 100, metric: .views))
        // 15% decrease in views - negative sentiment
        BadgeTrendIndicator(trend: TrendViewModel(currentValue: 85, previousValue: 100, metric: .views))
        // 0.1% increase in views - negative sentiment
        BadgeTrendIndicator(trend: TrendViewModel(currentValue: 1001, previousValue: 1000, metric: .views))

        Text("Edge Cases").font(.headline).padding(.top)
        // No change
        BadgeTrendIndicator(trend: TrendViewModel(currentValue: 100, previousValue: 100, metric: .views))
        // Division by zero (from 0 to 100)
        BadgeTrendIndicator(trend: TrendViewModel(currentValue: 100, previousValue: 0, metric: .views))
        // Large change
        BadgeTrendIndicator(trend: TrendViewModel(currentValue: 400, previousValue: 100, metric: .views))
    }
    .padding()
}
