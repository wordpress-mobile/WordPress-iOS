import SwiftUI
import WidgetKit

@available(iOS 16.0, *)
struct LockScreenMultiStatView: View {
    @Environment(\.widgetFamily) var family: WidgetFamily
    let viewModel: LockScreenMultiStatViewModel

    var body: some View {
        if family == .accessoryRectangular {
            ZStack {
                VStack(alignment: .leading) {
                    Spacer()
                    LockScreenSiteTitleView(title: viewModel.siteName)
                    Spacer().frame(height: 4)
                    HStack(alignment: .bottom) {
                        LockScreenFieldView(
                            title: viewModel.primaryField.title,
                            value: viewModel.primaryField.value.abbreviatedString(),
                            valueFontSize: constantValueFontSize()
                        )
                        Spacer()
                        Spacer()
                        LockScreenFieldView(
                            title: viewModel.secondaryField.title,
                            value: viewModel.secondaryField.value.abbreviatedString(),
                            valueFontSize: constantValueFontSize()
                        )
                        Spacer()
                    }
                    Spacer()
                }
            }
            .accessibilityElement(children: .combine)
        } else {
            Text("Not implemented for widget family \(family.debugDescription)")
        }
    }


    /// Calculates value font size based on the longest value between two fields
    ///
    /// There's no trivial way to synchronize font sizes between two fields
    /// Given we use abbreviated values, we can use hard-coded font size to ensure
    /// most of the cases are handled
    /// - Returns: Font Size
    private func constantValueFontSize() -> CGFloat {
        let primaryValue = viewModel.primaryField.value.abbreviatedString()
        let secondaryValue = viewModel.secondaryField.value.abbreviatedString()
        let length = CGFloat(max(primaryValue.count, secondaryValue.count))

        switch length {
        case 6...:
            return LockScreenFieldView.ValueFontSize.small
        case 5:
            return LockScreenFieldView.ValueFontSize.medium
        default:
            return LockScreenFieldView.ValueFontSize.default
        }
    }
}

@available(iOS 16.0, *)
struct LockScreenMultiStatView_Previews: PreviewProvider {
    static let viewModels = [
        LockScreenMultiStatViewModel(
            siteName: "My WordPress Site",
            updatedTime: Date(),
            primaryField: .init(title: "Likes", value: 373412),
            secondaryField: .init(title: "Best views", value: 75712)
        ),
        LockScreenMultiStatViewModel(
            siteName: "My WordPress Site",
            updatedTime: Date(),
            primaryField: .init(title: "Views", value: 1512),
            secondaryField: .init(title: "Visitors", value: 505)
        ),
        LockScreenMultiStatViewModel(
            siteName: "My WordPress Site",
            updatedTime: Date(),
            primaryField: .init(title: "Views", value: 15),
            secondaryField: .init(title: "Most Views", value: 5)
        ),
        LockScreenMultiStatViewModel(
            siteName: "My WordPress Site with an extremely long name",
            updatedTime: Date(),
            primaryField: .init(title: "Likes", value: 0),
            secondaryField: .init(title: "Comments", value: 373412)
        )
    ]

    static var previews: some View {
        Group {
            ForEach(LockScreenMultiStatView_Previews.viewModels, id: \.primaryField.value) {
                LockScreenMultiStatView(viewModel: $0)
            }
        }
        .previewContext(
            WidgetPreviewContext(family: .accessoryRectangular)
        )
    }
}
