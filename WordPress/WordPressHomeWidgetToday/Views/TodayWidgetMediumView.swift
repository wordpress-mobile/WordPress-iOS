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
                           upperValue: "\(content.stats.views.abbreviatedStringWithPlaceholder())",
                           lowerTitle: likesTitle,
                           lowerValue: "\(content.stats.likes.abbreviatedStringWithPlaceholder())")
                Spacer()
                Spacer()
                makeColumn(upperTitle: visitorsTitle,
                           upperValue: "\(content.stats.visitors.abbreviatedStringWithPlaceholder())",
                           lowerTitle: commentsTitle,
                           lowerValue: "\(content.stats.comments.abbreviatedStringWithPlaceholder())")
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
