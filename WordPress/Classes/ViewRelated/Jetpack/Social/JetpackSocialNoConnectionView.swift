import SwiftUI

struct JetpackSocialNoConnectionView: View {

    @StateObject private var viewModel: JetpackSocialNoConnectionViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12.0) {
            HStack(spacing: -5.0) {
                ForEach(viewModel.icons, id: \.self) { icon in
                    iconImage(icon)
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

    func iconImage(_ image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .frame(width: 32.0, height: 32.0)
            .background(Color(viewModel.preferredBackgroundColor))
            .clipShape(Circle())
            .overlay(Circle().stroke(Color(viewModel.preferredBackgroundColor), lineWidth: 2.0))
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

// MARK: - View model

class JetpackSocialNoConnectionViewModel: ObservableObject {
    let padding: EdgeInsets
    let hideNotNow: Bool
    let preferredBackgroundColor: UIColor
    let bodyTextColor: UIColor
    let onConnectTap: (() -> Void)?
    let onNotNowTap: (() -> Void)?
    @MainActor @Published var icons: [UIImage] = [UIImage()]

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
        updateIcons(services)
    }

    private func updateIcons(_ services: [PublicizeService]) {
        var icons: [UIImage] = []
        var downloadTasks: [(url: URL, index: Int)] = []
        for (index, service) in services.enumerated() {
            let icon = WPStyleGuide.socialIcon(for: service.serviceID as NSString)
            icons.append(icon)

            if service.name == .unknown {
                guard let iconUrl = URL(string: service.icon) else {
                    continue
                }
                downloadTasks.append((url: iconUrl, index: index))
            }
        }

        DispatchQueue.main.async {
            self.icons = icons

            for task in downloadTasks {
                let (url, index) = task
                Task { @MainActor in
                    if let image = try? await ImageDownloader.shared.image(from: url) {
                        self.icons[index] = image
                    }
                }
            }
        }
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
