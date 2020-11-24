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
                         value: content.siteName)
            Spacer()
            HStack {
                makeColumn(upperTitle: viewsTitle,
                           upperValue: "\(content.stats.views.abbreviatedString())",
                           lowerTitle: likesTitle,
                           lowerValue: "\(content.stats.likes.abbreviatedString())")
                Spacer()
                Spacer()
                makeColumn(upperTitle: visitorsTitle,
                           upperValue: "\(content.stats.visitors.abbreviatedString())",
                           lowerTitle: commentsTitle,
                           lowerValue: "\(content.stats.comments.abbreviatedString())")
                Spacer()
            }
        }
    }

    /// Constructs a two-card column for the medium size Today widget
    private func makeColumn(upperTitle: LocalizedStringKey,
                            upperValue: LocalizedStringKey,
                            lowerTitle: LocalizedStringKey,
                            lowerValue: LocalizedStringKey) -> some View {
        VStack(alignment: .leading) {
            VerticalCard(title: upperTitle, value: upperValue, largeText: false)
            Spacer()
            VerticalCard(title: lowerTitle, value: lowerValue, largeText: false)
        }
    }
 }
