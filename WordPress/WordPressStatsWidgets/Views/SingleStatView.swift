import SwiftUI

struct SingleStatView: View {

    let viewData: GroupedViewData


    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                FlexibleCard(axis: .vertical, title: viewData.widgetTitle, value: .description(viewData.siteName), lineLimit: 2)

                Spacer()
                VerticalCard(title: viewData.upperLeftTitle, value: viewData.upperLeftValue, largeText: true)
            }
            Spacer()
        }
        .flipsForRightToLeftLayoutDirection(true)
    }
}
