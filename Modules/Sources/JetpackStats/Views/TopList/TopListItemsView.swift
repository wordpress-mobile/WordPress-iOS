import SwiftUI

struct TopListItemsView: View {
    let data: TopListData
    let itemLimit: Int
    let dateRange: StatsDateRange
    var reserveSpace: Bool = false

    @ScaledMetric(relativeTo: .callout) private var cellHeight = 52

    var body: some View {
        VStack(spacing: Constants.step1 / 2) {
            ForEach(Array(data.items.prefix(itemLimit).enumerated()), id: \.element.id) { index, item in
                makeView(for: item)
                    .transition(.move(edge: .leading)
                        .combined(with: .scale(scale: 0.75))
                        .combined(with: .opacity))
            }

            if reserveSpace && data.items.count < itemLimit {
                ForEach(0..<(itemLimit - data.items.count), id: \.self) { _ in
                    PlaceholderRowView(height: cellHeight)
                }
            }
        }
        .padding(.horizontal, Constants.step1)
        .animation(.spring, value: ObjectIdentifier(data))
    }

    private func makeView(for item: any TopListItemProtocol) -> some View {
        TopListItemView(
            item: item,
            previousValue: data.previousItem(for: item)?.metrics[data.metric],
            metric: data.metric,
            maxValue: data.metrics.maxValue,
            dateRange: dateRange,
            totalValue: data.metrics.total
        )
        .frame(height: cellHeight)
    }
}

struct PlaceholderRowView: View {
    let height: CGFloat

    var body: some View {
        Rectangle()
            .fill(Color.clear)
            .background(
                LinearGradient(
                    colors: [
                        Color.secondary.opacity(0.05),
                        Color.secondary.opacity(0.02)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .clipShape(RoundedRectangle(cornerRadius: Constants.step1))
            )
            .frame(height: height)
    }
}
