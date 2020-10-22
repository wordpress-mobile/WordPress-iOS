 import SwiftUI

struct TodayWidgetMediumView: View {
    let content: TodayWidgetContent
    let siteNameTitle: LocalizedStringKey
    let viewsTitle: LocalizedStringKey
    let visitorsTitle: LocalizedStringKey
    let likesTitle: LocalizedStringKey
    let commentsTitle: LocalizedStringKey

    var body: some View {
        ZStack {
            VStack(alignment: .leading) {
                FlexibleCard(axis: .horizontal,
                             title: siteNameTitle,
                             value: content.siteTitle)
                Spacer()
                makeRow(leftTitle: viewsTitle,
                        leftValue: "\(content.views)",
                        rightTitle: visitorsTitle,
                        rightValue: "\(content.visitors)")
                Spacer()
                makeRow(leftTitle: likesTitle,
                        leftValue: "\(content.likes)",
                        rightTitle: commentsTitle,
                        rightValue: "\(content.comments)")
            }
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
