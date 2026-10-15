import SwiftUI
import DesignSystem

/// The content of the design card, inside the standard card chrome.
struct DashboardDesignCardView: View {
    let onChooseDesign: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: .DS.Padding.double) {
            Text(Strings.body)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Button(action: onChooseDesign) {
                Text(Strings.action)
                    .font(.callout)
                    .foregroundStyle(Color(UIAppColor.primary))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding([.leading, .trailing, .bottom], .DS.Padding.double)
    }
}

extension DashboardDesignCardView {
    enum Strings {
        static let title = NSLocalizedString(
            "dashboard.designCard.title",
            value: "Choose a design",
            comment: "Title of the Dashboard card that offers a design to a newly created site."
        )
        static let body = NSLocalizedString(
            "dashboard.designCard.body",
            value: "Pick a look for your site. You can change it anytime.",
            comment: "Body of the Dashboard card that offers a design to a newly created site."
        )
        static let action = NSLocalizedString(
            "dashboard.designCard.action",
            value: "Choose a design",
            comment: "Button on the Dashboard design card that opens the list of designs."
        )
    }
}
