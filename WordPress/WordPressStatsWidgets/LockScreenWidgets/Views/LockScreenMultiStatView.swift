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
                    LockScreenFieldView(title: viewModel.firstField.title, value: viewModel.firstField.value.abbreviatedString())
                    LockScreenFieldView(title: viewModel.secondaryField.title, value: viewModel.secondaryField.value.abbreviatedString())
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

struct LockScreenFieldView: View {
    var title: String
    var value: String

    var body: some View {
        HStack {
            Text(title)
                .frame(alignment: .leading)
                .font(.system(size: 11, weight: .bold))
                .minimumScaleFactor(0.8)
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer()
            Text(value)
                .frame(alignment: .trailing)
                .font(.system(size: 14, weight: .bold))
                .lineLimit(1)
        }
    }
}

@available(iOS 16.0, *)
struct LockScreenMultiStatView_Previews: PreviewProvider {
    static let viewModel = LockScreenMultiStatViewModel(
        siteName: "My WordPress Site",
        updatedTime: Date(),
        firstField: .init(title: "Views", value: 12345678),
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
