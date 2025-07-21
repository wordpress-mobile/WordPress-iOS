import SwiftUI

struct TopListItemsView: View {
    let data: TopListChartData
    let itemLimit: Int
    var showDetails = true

    var body: some View {
        VStack(spacing: Constants.step1 / 2) {
            ForEach(data.items.prefix(itemLimit), id: \.current.id) { item in
                TopListItemView(
                    currentItem: item.current,
                    previousItem: item.previous,
                    metric: data.metric,
                    maxValue: data.maxValue,
                    showDetails: showDetails
                )
                .transition(.opacity)
            }
        }
        .animation(.spring, value: data.items.map(\.current.id))
    }
}
