import SwiftUI

struct SingleStatView: View {
    let content: HomeWidgetData
    let widgetTitle: LocalizedStringKey
    let title: LocalizedStringKey

    private var views: Int {
        (content as? HomeWidgetTodayData)?.stats.views ?? (content as? HomeWidgetAllTimeData)?.stats.views ?? 0
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                FlexibleCard(axis: .vertical, title: widgetTitle, value: .description(content.siteName), lineLimit: 2)

                Spacer()
                VerticalCard(title: title, value: views, largeText: true)
            }
            Spacer()
        }
        .flipsForRightToLeftLayoutDirection(true)
    }
}
