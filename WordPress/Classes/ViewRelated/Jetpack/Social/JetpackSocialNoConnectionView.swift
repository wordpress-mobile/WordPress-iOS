import SwiftUI

struct JetpackSocialNoConnectionView: View {

    private let viewModel: JetpackSocialNoConnectionViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12.0) {
            HStack(spacing: -5.0) {
                ForEach(viewModel.icons, id: \.self) { icon in
                    iconImage(image: icon.image, url: icon.url)
                }
            }
            .accessibilityElement()
            .accessibilityLabel(Constants.iconGroupAccessibilityLabel)
            Text(Constants.bodyText)
                .font(.callout)
                .foregroundColor(Color(viewModel.bodyTextColor))
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
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(viewModel.padding)
        .background(Color(viewModel.preferredBackgroundColor))
    }

    func iconImage(image: UIImage, url: URL?) -> some View {
        AsyncImage(url: url) { image in
            image
                .icon(backgroundColor: viewModel.preferredBackgroundColor)
        } placeholder: {
            Image(uiImage: image)
                .icon(backgroundColor: viewModel.preferredBackgroundColor)
        }
    }
}

// MARK: - JetpackSocialNoConnectionView Extension

extension JetpackSocialNoConnectionView {
    static func createHostController(with viewModel: JetpackSocialNoConnectionViewModel = JetpackSocialNoConnectionViewModel()) -> UIHostingController<JetpackSocialNoConnectionView> {
        let hostController = UIHostingController(rootView: JetpackSocialNoConnectionView(viewModel: viewModel))
        hostController.view.translatesAutoresizingMaskIntoConstraints = false
        hostController.view.backgroundColor = viewModel.preferredBackgroundColor
        return hostController
    }
}

// MARK: - Image Extension

private extension Image {
    func icon(backgroundColor: UIColor) -> some View {
        self
            .resizable()
            .frame(width: 32.0, height: 32.0)
            .background(Color(backgroundColor))
            .clipShape(Circle())
            .overlay(Circle().stroke(Color(backgroundColor), lineWidth: 2.0))
    }
}

// MARK: - View model

struct JetpackSocialNoConnectionViewModel {

    struct IconInfo: Hashable {
        let image: UIImage
        let url: URL?
    }

    let padding: EdgeInsets
    let hideNotNow: Bool
    let preferredBackgroundColor: UIColor
    let bodyTextColor: UIColor
    let onConnectTap: (() -> Void)?
    let onNotNowTap: (() -> Void)?
    let icons: [IconInfo]

    init(services: [PublicizeService] = [],
         padding: EdgeInsets = Constants.defaultPadding,
         hideNotNow: Bool = false,
         preferredBackgroundColor: UIColor? = nil,
         bodyTextColor: UIColor = .label,
         onConnectTap: (() -> Void)? = nil,
         onNotNowTap: (() -> Void)? = nil) {
        self.padding = padding
        self.hideNotNow = hideNotNow
        self.preferredBackgroundColor = preferredBackgroundColor ?? Constants.defaultBackgroundColor
        self.bodyTextColor = bodyTextColor
        self.onConnectTap = onConnectTap
        self.onNotNowTap = onNotNowTap

        var images = [IconInfo]()
        for service in services {
            let icon = WPStyleGuide.socialIcon(for: service.serviceID as NSString)
            let url: URL? = service.name == .unknown ? URL(string: service.icon) : nil
            images.append(IconInfo(image: icon, url: url))
        }
        self.icons = images
    }

}

// MARK: - Constants

private struct Constants {
    static let defaultPadding = EdgeInsets(top: 16.0, leading: 16.0, bottom: 24.0, trailing: 16.0)
    static let defaultBackgroundColor = UIColor.listForeground
    static let bodyText = NSLocalizedString("social.noconnection.body",
                                            value: "Increase your traffic by auto-sharing your posts with your friends on social media.",
                                            comment: "Body text for the Jetpack Social no connection view")
    static let connectText = NSLocalizedString("social.noconnection.connectAccounts",
                                               value: "Connect accounts",
                                               comment: "Title for the connect button to add social sharing for the Jetpack Social no connection view")
    static let notNowText = NSLocalizedString("social.noconnection.notnow",
                                              value: "Not now",
                                              comment: "Title for the not now button to hide the Jetpack Social no connection view")
    static let iconGroupAccessibilityLabel = NSLocalizedString("social.noconnection.icons.accessibility.label",
                                                               value: "Social media icons",
                                                               comment: "Accessibility label for the social media icons in the Jetpack Social no connection view")

}
