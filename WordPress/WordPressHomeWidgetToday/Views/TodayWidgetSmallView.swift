import SwiftUI

struct TodayWidgetSmallView: View {
    let content: TodayWidgetContent
    let siteNameTitle: LocalizedStringKey
    let viewsTitle: LocalizedStringKey

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                FlexibleCard(axis: .vertical, title: siteNameTitle, value: content.siteTitle)

                Spacer()
                VerticalCard(title: viewsTitle, value: "\(content.views)", largeText: true)
            }
            Spacer()
        }
    }
}
