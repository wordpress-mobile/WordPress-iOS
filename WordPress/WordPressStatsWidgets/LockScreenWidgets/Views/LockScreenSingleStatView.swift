import SwiftUI
import WidgetKit

@available(iOS 16.0, *)
struct LockScreenSingleStatView: View {
    @Environment(\.sizeCategory) var sizeCategory
    @Environment(\.widgetFamily) var family: WidgetFamily
    let viewModel: LockScreenSingleStatViewModel

    var body: some View {
        if family == .accessoryRectangular {
            ZStack {
                AccessoryWidgetBackground().cornerRadius(8)
                VStack(alignment: .leading) {
                    Text(viewModel.siteName)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.caption2)
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)
                    if sizeCategory <= ContentSizeCategory.large {
                        VStack {
                            Text(viewModel.value)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .font(.title3)
                                .minimumScaleFactor(0.5)
                                .foregroundColor(.white)
                            Text("\(viewModel.title) \(viewModel.dateRange)")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .font(.caption2)
                                .minimumScaleFactor(0.8)
                        }
                    } else {
                        HStack {
                            Text(viewModel.value)
                                .font(.title3)
                                .minimumScaleFactor(0.1)
                                .foregroundColor(.white)
                            VStack {
                                Text(viewModel.title)
                                    .font(.headline)
                                    .minimumScaleFactor(0.5)
                                Text(viewModel.dateRange)
                                    .font(.headline)
                                    .minimumScaleFactor(0.5)
                            }
                        }
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
struct LockScreenSingleStatView_Previews: PreviewProvider {
    static let viewModel = LockScreenSingleStatViewModel(
        siteName: "My WordPress Site",
        title: "Views",
        value: 649123.abbreviatedString(),
        dateRange: "Today",
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
