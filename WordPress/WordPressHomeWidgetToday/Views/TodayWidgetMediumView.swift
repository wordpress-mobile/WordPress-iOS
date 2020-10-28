 import SwiftUI

 struct TodayWidgetMediumView: View {
    let content: TodayWidgetContent
    let widgetTitle: LocalizedStringKey
    let viewsTitle: LocalizedStringKey
    let visitorsTitle: LocalizedStringKey
    let likesTitle: LocalizedStringKey
    let commentsTitle: LocalizedStringKey

    var body: some View {
        VStack(alignment: .leading) {
            FlexibleCard(axis: .horizontal,
                         title: widgetTitle,
                         value: content.siteTitle)
            Spacer()
            HStack {
                makeColumn(upperTitle: viewsTitle,
                           upperValue: "\(content.views)",
                           lowerTitle: likesTitle,
                           lowerValue: "\(content.likes)")
                Spacer()
                Spacer()
                makeColumn(upperTitle: visitorsTitle,
                           upperValue: "\(content.visitors)",
                           lowerTitle: commentsTitle,
                           lowerValue: "\(content.comments)")
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
