import SwiftUI
import WidgetKit

@available(iOS 16.0, *)
struct LockScreenMultiStatView: View {
    @Environment(\.widgetFamily) var family: WidgetFamily
    let viewModel: LockScreenMultiStatViewModel

    var body: some View {
        if family == .accessoryRectangular {
            ZStack {
                AccessoryWidgetBackground().cornerRadius(8)
                VStack(alignment: .leading) {
                    LockScreenSiteTitleView(title: viewModel.siteName)
                    Spacer(minLength: 0)
                    HStack {
                        LockScreenFieldView(title: viewModel.firstField.title, value: viewModel.firstField.value)
                        Spacer()
                        Spacer()
                        LockScreenFieldView(title: viewModel.secondaryField.title, value: viewModel.secondaryField.value)
                        Spacer()
                    }
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
struct LockScreenMultiStatView_Previews: PreviewProvider {
    static let viewModel = LockScreenMultiStatViewModel(
        siteName: "My WordPress Site",
        updatedTime: Date(),
        firstField: .init(title: "Likes", value: 12345678),
        secondaryField: .init(title: "Comments", value: 1280)
    )

    static var previews: some View {
        Group {
            LockScreenMultiStatView(
                viewModel: LockScreenMultiStatView_Previews.viewModel
            )
            .previewContext(
                WidgetPreviewContext(family: .accessoryRectangular)
            )
        }
    }
}
