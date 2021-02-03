import SwiftUI

struct TodayWidgetSmallView: View {
    let content: HomeWidgetData
    let widgetTitle: LocalizedStringKey
    let viewsTitle: LocalizedStringKey

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                FlexibleCard(axis: .vertical, title: widgetTitle, value: .description(content.siteName))

                Spacer()
                VerticalCard(title: viewsTitle, value: (content as? HomeWidgetTodayData)?.stats.views ?? (content as? HomeWidgetAllTimeData)?.stats.views ?? 0, largeText: true)
            }
            Spacer()
        }
        .flipsForRightToLeftLayoutDirection(true)
    }
}
