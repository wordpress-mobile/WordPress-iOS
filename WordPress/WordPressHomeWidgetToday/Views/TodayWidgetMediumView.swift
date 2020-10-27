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
            makeRow(leftTitle: viewsTitle,
                    leftValue: "\(content.stats.views)",
                    rightTitle: visitorsTitle,
                    rightValue: "\(content.stats.visitors)")
            Spacer()
            makeRow(leftTitle: likesTitle,
                    leftValue: "\(content.stats.likes)",
                    rightTitle: commentsTitle,
                    rightValue: "\(content.stats.comments)")
        }
    }
    /// Constructs a two-card row for the medium size Today widget
    private func makeRow(leftTitle: LocalizedStringKey,
                         leftValue: LocalizedStringKey,
                         rightTitle: LocalizedStringKey,
                         rightValue: LocalizedStringKey) -> some View {
        HStack {
            VerticalCard(title: leftTitle, value: leftValue, largeText: false)
            Spacer()
            Spacer()
            VerticalCard(title: rightTitle, value: rightValue, largeText: false)
            Spacer()
        }
    }
 }
