import SwiftUI
import WidgetKit

struct SingleStatView: View {

    let title: String
    let description: String
    let valueTitle: String
    let value: Int

    init(viewData: GroupedViewData) {
        self.title = viewData.widgetTitle
        self.description = viewData.siteName
        self.valueTitle = viewData.upperLeftTitle
        self.value = viewData.upperLeftValue
    }

    init(title: String, description: String, valueTitle: String, value: Int) {
        self.title = title
        self.description = description
        self.valueTitle = valueTitle
        self.value = value
    }


    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                FlexibleCard(axis: .vertical, title: title, value: .description(description), lineLimit: 2)

                Spacer()
                VerticalCard(title: valueTitle, value: value, largeText: true)
            }
            Spacer()
        }
    }
}

@available(iOS 16.0, *)
struct SingleStatView_Previews: PreviewProvider {
    static var previews: some View {
        SingleStatView(title: "My WordPress Site", description: "Today", valueTitle: "Views", value: 124909)
            .previewContext(
                WidgetPreviewContext(family: .systemSmall)
            )
    }
}
