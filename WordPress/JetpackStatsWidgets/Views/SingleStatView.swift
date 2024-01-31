import SwiftUI
import WidgetKit

struct SingleStatView: View {
    let title: String
    let description: String
    let valueTitle: String
    let value: Int

    @Environment(\.showsWidgetContainerBackground) var showsWidgetContainerBackground: Bool

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
            if showsWidgetContainerBackground {
                VStack(alignment: .leading) {
                    FlexibleCard(axis: .vertical, title: title, value: .description(description), lineLimit: 2)
                    Spacer()
                    VerticalCard(title: valueTitle, value: value, largeText: true)
                }
                .padding()
            } else {
                VStack(alignment: .leading) {
                    Spacer()
                    LockScreenFlexibleCard(title: title, description: description, lineLimit: 2)
                    Spacer().frame(height: 4)
                    LockScreenVerticalCard(title: valueTitle, value: value)
                    Spacer()
                }
            }
            Spacer()
        }
        .removableWidgetBackground()
    }
}

@available(iOS 16.0, *)
struct SingleStatView_Previews: PreviewProvider {
    static var previews: some View {
        SingleStatView(title: "Today", description: "My WordPress Site", valueTitle: "Views", value: 124909)
            .previewContext(
                WidgetPreviewContext(family: .systemSmall)
            )
    }
}
