import SwiftUI

struct TodayWidgetSmallView: View {
    let content: HomeWidgetTodayData
    let widgetTitle: LocalizedStringKey
    let viewsTitle: LocalizedStringKey

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                FlexibleCard(axis: .vertical, title: widgetTitle, value: .description(content.siteName), lineLimit: 2)

                Spacer()
                VerticalCard(title: viewsTitle, value: content.stats.views, largeText: true)
            }
            Spacer()
        }
        .flipsForRightToLeftLayoutDirection(true)
    }
}
