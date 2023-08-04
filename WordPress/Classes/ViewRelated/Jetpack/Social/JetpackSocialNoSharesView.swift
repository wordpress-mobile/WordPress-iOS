import SwiftUI

struct JetpackSocialNoSharesView: View {

    let viewModel: JetpackSocialNoSharesViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 4.0) {
            HStack(spacing: -5.0) {
                ForEach(viewModel.services, id: \.self) { service in
                    iconImage(service.localIconImage)
                }
            }
            .padding(.bottom, 8.0)
            .accessibilityElement()
            .accessibilityLabel(Constants.iconGroupAccessibilityLabel)
            Text(bodyText)
                .font(.callout)
                .foregroundColor(Color(UIColor.secondaryLabel))
                .padding(.bottom, 5.0)
            Text(Constants.subscribeText)
                .font(.callout)
                .foregroundColor(Color(UIColor.primary))
                .onTapGesture {
                    viewModel.onSubscribeTap()
                }
                .accessibilityAddTraits(.isButton)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(EdgeInsets(top: 0.0, leading: 16.0, bottom: 8.0, trailing: 16.0))
    }

    var bodyText: String {
        if viewModel.totalServiceCount > 1 {
            return String(format: Constants.pluralShareTextFormat, viewModel.totalServiceCount)
        }
        return Constants.singularShareText
    }

    func iconImage(_ image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .frame(width: 32.0, height: 32.0)
            .opacity(0.36)
            .background(Color(UIColor.listForeground))
            .clipShape(Circle())
            .overlay(Circle().stroke(Color(UIColor.listForeground), lineWidth: 2.0))
    }
}

// MARK: - View model

struct JetpackSocialNoSharesViewModel {

    let services: [PublicizeService.ServiceName]
    let totalServiceCount: Int
    let onSubscribeTap: () -> Void

    init(services: [PublicizeService.ServiceName], totalServiceCount: Int, onSubscribeTap: @escaping () -> Void) {
        self.services = services
        self.totalServiceCount = totalServiceCount
        self.onSubscribeTap = onSubscribeTap
    }

}

// MARK: - Constants

private struct Constants {

    static let pluralShareTextFormat = NSLocalizedString("social.noshares.body.plural",
                                                         value: "Your posts won’t be shared to your %1$d social accounts.",
                                                         comment: "Plural body text for the Jetpack Social no shares dashboard card. %1$d is the number of social accounts the user has.")
    static let singularShareText = NSLocalizedString("social.noshares.body.singular",
                                                     value: "Your posts won’t be shared to your social account.",
                                                     comment: "Singular body text for the Jetpack Social no shares dashboard card.")
    static let subscribeText = NSLocalizedString("social.noshares.subscribe",
                                                 value: "Subscribe to share more",
                                                 comment: "Title for the button to subscribe to Jetpack Social on the no shares dashboard card")
    static let iconGroupAccessibilityLabel = NSLocalizedString("social.noshares.icons.accessibility.label",
                                                               value: "Social media icons",
                                                               comment: "Accessibility label for the social media icons in the Jetpack Social no shares dashboard card")
}
