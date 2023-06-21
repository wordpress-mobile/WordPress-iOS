import SwiftUI

struct JetpackSocialNoConnectionView: View {

    private let viewModel: JetpackSocialNoConnectionViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12.0) {
            HStack(spacing: -5.0) {
                iconImage("icon-tumblr")
                iconImage("icon-facebook")
                iconImage("icon-twitter")
                iconImage("icon-linkedin")
            }
            .accessibilityElement()
            .accessibilityLabel(Constants.iconGroupAccessibilityLabel)
            Text(Constants.bodyText)
                .font(.callout)
            HStack {
                Text(Constants.connectText)
                    .font(.callout)
                    .foregroundColor(Color(UIColor.primary))
                    .onTapGesture {
                        viewModel.onConnectTap?()
                    }
                if !viewModel.hideNotNow {
                    Spacer()
                    Text(Constants.notNowText)
                        .font(.callout)
                        .foregroundColor(Color(UIColor.primary))
                        .onTapGesture {
                            viewModel.onNotNowTap?()
                        }
                }
            }
        }
        .padding(viewModel.padding)
        .background(Color(UIColor.listForeground))
    }

    func iconImage(_ image: String) -> some View {
       Image(image)
            .resizable()
            .frame(width: 32.0, height: 32.0)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color(UIColor.listForeground), lineWidth: 2.0))
    }
}

// MARK: - JetpackSocialNoConnectionView Extension

extension JetpackSocialNoConnectionView {
    static func createHostController(with viewModel: JetpackSocialNoConnectionViewModel = JetpackSocialNoConnectionViewModel()) -> UIHostingController<JetpackSocialNoConnectionView> {
        let hostController = UIHostingController(rootView: JetpackSocialNoConnectionView(viewModel: viewModel))
        hostController.view.translatesAutoresizingMaskIntoConstraints = false
        return hostController
    }
}

// MARK: - View model

struct JetpackSocialNoConnectionViewModel {
    let padding: EdgeInsets
    let hideNotNow: Bool
    let onConnectTap: (() -> Void)?
    let onNotNowTap: (() -> Void)?

    init(padding: EdgeInsets = Constants.defaultPadding,
         hideNotNow: Bool = false,
         onConnectTap: (() -> Void)? = nil,
         onNotNowTap: (() -> Void)? = nil) {
        self.padding = padding
        self.hideNotNow = hideNotNow
        self.onConnectTap = onConnectTap
        self.onNotNowTap = onNotNowTap
    }
}

// MARK: - Constants

private struct Constants {
    static let defaultPadding = EdgeInsets(top: 16.0, leading: 16.0, bottom: 24.0, trailing: 16.0)
    static let bodyText = NSLocalizedString("social.noconnection.body",
                                            value: "Increase your traffic by auto-sharing your posts with your friends on social media.",
                                            comment: "Body text for the Jetpack Social no connection view")
    static let connectText = NSLocalizedString("social.noconnection.connect",
                                               value: "Connect your profiles",
                                               comment: "Title for the connect button to add social sharing for the Jetpack Social no connection view")
    static let notNowText = NSLocalizedString("social.noconnection.notnow",
                                              value: "Not now",
                                              comment: "Title for the not now button to hide the Jetpack Social no connection view")
    static let iconGroupAccessibilityLabel = NSLocalizedString("social.noconnection.icons.accessibility.label",
                                                               value: "Social media icons",
                                                               comment: "Accessibility label for the social media icons in the Jetpack Social no connection view")

}
