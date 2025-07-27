import SwiftUI

struct TopListItemsView: View {
    let data: TopListChartData
    let itemLimit: Int
    let dateRange: StatsDateRange


    var body: some View {
        VStack(spacing: Constants.step1 / 2) {
            ForEach(data.items.prefix(itemLimit), id: \.id) { item in
                makeView(for: item)
                    .transition(.move(edge: .leading)
                        .combined(with: .scale(scale: 0.75))
                        .combined(with: .opacity))
            }
        }
        .animation(.spring, value: ObjectIdentifier(data))
    }


    private func makeView(for item: any TopListItem) -> some View {
        TopListItemView(
            item: item,
            previousValue: data.previousItem(for: item)?.metrics[data.metric],
            metric: data.metric,
            maxValue: data.maxValue,
            dateRange: dateRange
        )
    }

}
