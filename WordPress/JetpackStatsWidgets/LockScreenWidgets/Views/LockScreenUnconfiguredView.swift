import SwiftUI
import WidgetKit

@available(iOS 16.0, *)
struct LockScreenUnconfiguredView: View {
    @Environment(\.widgetFamily) var family: WidgetFamily
    let viewModel: LockScreenUnconfiguredViewModel

    var body: some View {
        if family == .accessoryRectangular {
            ZStack {
                AccessoryWidgetBackground().cornerRadius(8)
                Text(viewModel.message)
                    .font(.system(size: 11))
                    .minimumScaleFactor(0.8)
                    .multilineTextAlignment(.center)
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
struct LockScreenUnconfiguredView_Previews: PreviewProvider {
    static let viewModel = LockScreenUnconfiguredViewModel(
        message: "Log in to Jetpack to see today's stats."
    )

    static var previews: some View {
        LockScreenUnconfiguredView(
            viewModel: LockScreenUnconfiguredView_Previews.viewModel
        )
        .previewContext(
            WidgetPreviewContext(family: .accessoryRectangular)
        )
    }
}
