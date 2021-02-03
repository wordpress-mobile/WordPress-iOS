 import SwiftUI

 struct TodayWidgetMediumView: View {
    let content: HomeWidgetData
    let widgetTitle: LocalizedStringKey
    let viewsTitle: LocalizedStringKey
    let visitorsTitle: LocalizedStringKey
    let likesTitle: LocalizedStringKey
    let commentsTitle: LocalizedStringKey

    var body: some View {
        VStack(alignment: .leading) {
            FlexibleCard(axis: .horizontal,
                         title: widgetTitle,
                         value: .description(content.siteName))
            Spacer()
            HStack {
                makeColumn(upperTitle: viewsTitle,
                           upperValue: (content as? HomeWidgetTodayData)?.stats.views ?? (content as? HomeWidgetAllTimeData)?.stats.views ?? 0,
                           lowerTitle: likesTitle,
                           lowerValue: (content as? HomeWidgetTodayData)?.stats.likes ?? (content as? HomeWidgetAllTimeData)?.stats.posts ?? 0)
                Spacer()
                Spacer()
                makeColumn(upperTitle: visitorsTitle,
                           upperValue: (content as? HomeWidgetTodayData)?.stats.visitors ?? (content as? HomeWidgetAllTimeData)?.stats.visitors ?? 0,
                           lowerTitle: commentsTitle,
                           lowerValue: (content as? HomeWidgetTodayData)?.stats.comments ?? (content as? HomeWidgetAllTimeData)?.stats.bestViews ?? 0)
                Spacer()
            }
        }
    }

    /// Constructs a two-card column for the medium size Today widget
    private func makeColumn(upperTitle: LocalizedStringKey,
                            upperValue: Int,
                            lowerTitle: LocalizedStringKey,
                            lowerValue: Int) -> some View {
        VStack(alignment: .leading) {
            VerticalCard(title: upperTitle, value: upperValue, largeText: false)
            Spacer()
            VerticalCard(title: lowerTitle, value: lowerValue, largeText: false)
        }
    }
 }
