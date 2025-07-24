import SwiftUI

struct TopListItemsView: View {
    let data: TopListChartData
    let itemLimit: Int
    let dateRange: StatsDateRange
    var showDetails = true

    var body: some View {
        VStack(spacing: Constants.step1 / 2) {
            ForEach(data.items.prefix(itemLimit)) { item in
                TopListItemView(
                    currentItem: item.current,
                    previousItem: item.previous,
                    metric: data.metric,
                    maxValue: data.maxValue,
                    showDetails: showDetails,
                    dateRange: dateRange
                )
                .transition(.move(edge: .leading)
                    .combined(with: .scale(scale: 0.75))
                    .combined(with: .opacity))
            }
        }
        .animation(.spring, value: ObjectIdentifier(data))
    }
}
