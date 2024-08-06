import SwiftUI
import WidgetKit

struct LockScreenSingleStatView: View {
    @Environment(\.widgetFamily) var family: WidgetFamily
    let viewModel: LockScreenSingleStatViewModel

    var body: some View {
        if family == .accessoryRectangular {
            ZStack {
                VStack(alignment: .leading) {
                    Spacer()
                    LockScreenSiteTitleView(title: viewModel.siteName)
                    Spacer().frame(height: 4)
                    LockScreenFieldView(title: viewModel.title, value: viewModel.value.abbreviatedString())
                    Spacer()
                }
            }
            .removableWidgetBackground()
            .accessibilityElement(children: .combine)
        } else {
            Text("Not implemented for widget family \(family.debugDescription)")
                .removableWidgetBackground()
        }
    }
}

struct LockScreenSingleStatView_Previews: PreviewProvider {
    static let viewModel = LockScreenSingleStatViewModel(
        siteName: "My WordPress Site",
        title: "Views Today",
        value: 646,
        updatedTime: Date()
    )

    static var previews: some View {
        LockScreenSingleStatView(
            viewModel: LockScreenSingleStatView_Previews.viewModel
        )
        .previewContext(
            WidgetPreviewContext(family: .accessoryRectangular)
        )
    }
}
