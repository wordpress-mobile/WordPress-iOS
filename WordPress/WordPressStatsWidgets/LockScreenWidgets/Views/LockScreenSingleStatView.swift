import SwiftUI
import WidgetKit

@available(iOS 16.0, *)
struct LockScreenSingleStatView: View {
    @Environment(\.widgetFamily) var family: WidgetFamily
    let viewModel: LockScreenSingleStatViewModel

    var body: some View {
        if family == .accessoryRectangular {
            ZStack {
                AccessoryWidgetBackground().cornerRadius(8)
                VStack(alignment: .leading) {
                    LockScreenSiteTitleView(title: viewModel.siteName)
                    Spacer(minLength: 0)
                    Text(viewModel.value)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.system(size: 20, weight: .bold))
                        .minimumScaleFactor(0.5)
                        .foregroundColor(.white)
                    Text(viewModel.title)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.system(size: 11, weight: .bold))
                        .minimumScaleFactor(0.8)
                }
                .padding(
                    EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
                )
            }
        } else {
            Text("Not implemented for widget family \(family.debugDescription)")
        }
    }
}

@available(iOS 16.0, *)
struct LockScreenSingleStatView_Previews: PreviewProvider {
    static let viewModel = LockScreenSingleStatViewModel(
        siteName: "My WordPress Site",
        title: "Views Today",
        value: "649",
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
