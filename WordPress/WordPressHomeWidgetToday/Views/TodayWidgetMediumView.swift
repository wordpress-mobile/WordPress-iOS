 import SwiftUI

 struct TodayWidgetMediumView: View {
    let content: HomeWidgetTodayData
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
                           upperValue: content.stats.views,
                           lowerTitle: likesTitle,
                           lowerValue: content.stats.likes)
                Spacer()
                Spacer()
                makeColumn(upperTitle: visitorsTitle,
                           upperValue: content.stats.visitors,
                           lowerTitle: commentsTitle,
                           lowerValue: content.stats.comments)
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
