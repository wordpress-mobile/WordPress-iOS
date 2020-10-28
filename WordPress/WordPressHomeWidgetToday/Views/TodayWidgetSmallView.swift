import SwiftUI

struct TodayWidgetSmallView: View {
    let content: TodayWidgetContent
    let widgetTitle: LocalizedStringKey
    let viewsTitle: LocalizedStringKey

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                FlexibleCard(axis: .vertical, title: widgetTitle, value: content.siteTitle)

                Spacer()
                VerticalCard(title: viewsTitle, value: "\(content.views)", largeText: true)
            }
            Spacer()
        }
        .flipsForRightToLeftLayoutDirection(true)
    }
}
