import SwiftUI
import AuthenticationServices
import WordPressAPI
import WordPressAuthenticator
import DesignSystem

struct LoginWithUrlView: View {

    private let client: SelfHostedSiteAuthenticator
    private let loginCompleted: (WordPressOrgCredentials) -> Void

    // Since the anchor is a window that typically is the window this view is presented in,
    // using a weak reference here to avoid retain cycle.
    private weak var anchor: ASPresentationAnchor?

    @State fileprivate var errorMessage: String?
    @State private var urlField: String = ""
    @State private var isLoading = false

    private var isContinueButtonDisabled: Bool {
        isLoading || urlField.trim().isEmpty
    }

    init(
        client: SelfHostedSiteAuthenticator,
        anchor: ASPresentationAnchor,
        loginCompleted: @escaping (WordPressOrgCredentials) -> Void
    ) {
        self.client = client
        self.anchor = anchor
        self.loginCompleted = loginCompleted
    }

    var body: some View {
        VStack(alignment: .leading) {
            Image("splashLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 60, height: 60)
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .center)

            Text(Self.enterSiteAddress)

            siteAdddressTextField()

            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
            }

            Spacer()

            DSButton(
                title: SharedStrings.Button.continue,
                style: DSButtonStyle(emphasis: .primary, size: .large),
                isLoading: .constant(isLoading),
                action: startLogin
            )
            .disabled(isContinueButtonDisabled)
        }
        .padding()
        .navigationTitle(Self.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func siteAdddressTextField() -> some View {
        TextField(text: $urlField) {
            Text("example.com")
        }
        .padding(.top)
        .padding(.bottom, 8)
        .overlay(alignment: .bottom) { Divider() }
        .overlay(Divider(), alignment: .bottom)
        .tint(.green)
        .textContentType(.URL)
        .keyboardType(.URL)
        .textInputAutocapitalization(.never)
        .onSubmit(startLogin)
        .disabled(isLoading)
    }

    private func startLogin() {
        errorMessage = nil
        isLoading = true

        // The Swift compiler isn't happy about placing this do-catch function body inside a Task.
        // https://github.com/swiftlang/swift/issues/76807
        func login() async {
            do {
                let credentials = try await client.signIn(site: urlField, from: anchor)
                self.loginCompleted(credentials)
            } catch {
                errorMessage = error.errorMessage
            }

            isLoading = false
        }

        Task { @MainActor in
            await login()
        }
    }
}

private extension LoginWithUrlView {
    static var title: String { NSLocalizedString("addSite.selfHosted.title", value: "Add Self-Hosted Site", comment: "Title of the page to add a self-hosted site") }
    static var enterSiteAddress: String { NSLocalizedString("addSite.selfHosted.enterSiteAddress", value: "Enter the address of the WordPress site you'd like to connect.", comment: "A message to inform users to type the site address in the text field.") }
}

private extension SelfHostedSiteAuthenticator.SignInError {

    var errorMessage: String? {
        switch self {
        case let .authentication(error):
            return error.errorMessage
        case .loadingSiteInfoFailure:
            return NSLocalizedString("addSite.selfHosted.loadingSiteInfoFailure", value: "Cannot load the WordPress site details", comment: "Error message shown when failing to load details from a self-hosted WordPress site")
        case .savingSiteFailure:
            return NSLocalizedString("addSite.selfHosted.savingSiteFailure", value: "Cannot save the WordPress site, please try again later.", comment: "Error message shown when failing to save a self-hosted site to user's device")
        }
    }

}

extension WordPressLoginClientError {

    var errorMessage: String? {
        switch self {
        case let .invalidSiteAddress(error):
            return error.errorMessage
        case .missingLoginUrl:
            return NSLocalizedString("addSite.selfHosted.noLoginUrlFound", value: "Application Password authentication needs to be enabled on the WordPress site.", comment: "Error message shown when application-password authentication is disabled on a self-hosted WordPress site")
        case .cancelled:
            return nil
        case .authenticationError, .invalidApplicationPasswordCallback:
            return NSLocalizedString("addSite.selfHosted.authenticationFailed", value: "Cannot login using Application Password authentication.", comment: "Error message shown when an receiving an invalid application-password authentication result from a self-hosted WordPress site")
        case .unknown:
            return NSLocalizedString("addSite.selfHosted.unknownError", value: "Something went wrong. Please try again.", comment: "Error message when an unknown error occurred when adding a self-hosted site")
        }
    }

}

// MARK: - WordPressAPI helpers

private extension UrlDiscoveryError {
    var errorMessage: String? {
        let errors: [UrlDiscoveryAttemptError]

        switch self {
        case let .UrlDiscoveryFailed(attempts):
            errors = attempts.values.compactMap {
                switch $0 {
                case let .failure(failure):
                    return failure
                case .success:
                    return nil
                }
            }
        }

        let notWordPressSite = errors.contains {
            switch $0 {
            case .fetchApiRootUrlFailed, .fetchApiDetailsFailed:
                return true
            case .failedToParseSiteUrl:
                return false
            }
        }

        if notWordPressSite {
            return NSLocalizedString("addSite.restApiNotAvailable", value: "The site at this address is not a WordPress site. For us to connect to it, the site must use WordPress.", comment: "Error message shown a URL does not point to an existing site.")
        }

        return NSLocalizedString("addSite.selfHosted.invalidUrl", value: "The site address is not valid.", comment: "Error message when user input is not a WordPress site")
    }
}

// MARK: - SwiftUI Preview

#Preview {
    LoginWithUrlView(
        client: .init(session: .shared),
        anchor: ASPresentationAnchor()
    ) { _ in }
}
