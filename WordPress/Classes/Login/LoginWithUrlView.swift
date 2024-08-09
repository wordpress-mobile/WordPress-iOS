import SwiftUI
import AuthenticationServices
import WordPressAPI
import WordPressAuthenticator

struct LoginWithUrlView: View {

    private let client: LoginClient
    private let loginCompleted: (WordPressOrgCredentials) -> Void

    // Since the anchor is a window that typically is the window this view is presented in,
    // using a weak reference here to avoid retain cycle.
    private weak var anchor: ASPresentationAnchor?

    @State fileprivate var errorMessage: String?
    @State private var urlField: String = ""
    @State private var isLoading = false

    init(
        anchor: ASPresentationAnchor,
        loginCompleted: @escaping (WordPressOrgCredentials) -> Void
    ) {
        self.client = LoginClient(session: URLSession(configuration: .ephemeral))
        self.anchor = anchor
        self.loginCompleted = loginCompleted
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text("Enter the address of the WordPress site you'd like to connect.").padding(.vertical)

            TextField(text: $urlField) {
                Text("example.com")
            }
            .padding(.vertical)
            .overlay(Divider(), alignment: .bottom)
            .tint(.green)
            .keyboardType(.URL)
            .textInputAutocapitalization(.never)
            .onSubmit(startLogin)
            .disabled(isLoading)

            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
            }

            Spacer()

            Button(action: startLogin, label: {
                HStack(alignment: .center) {
                    Spacer()
                    if isLoading {
                        ProgressView()
                    } else {
                        Text("Continue")
                    }
                    Spacer()
                }
                .animation(.default, value: 0)
                .padding()
                .background(
                    RoundedRectangle(
                        cornerRadius: .DS.Radius.small,
                        style: .continuous
                    )
                    .stroke(.primary, lineWidth: 2)
                )
            })
            .tint(.primary)
        }.padding()
    }

    func startLogin() {
        errorMessage = nil
        isLoading = true

        Task { @MainActor in
            let credentials = await client.login(site: urlField, from: anchor)
            switch credentials {
            case let .success(credentials):
                self.loginCompleted(credentials)
            case let .failure(error):
                errorMessage = error.errorMessage
            }

            isLoading = false
        }
    }
}

private extension LoginClient.LoginClientError {

    var errorMessage: String? {
        switch self {
        case let .invalidSiteAddress(error):
            return error.errorMessage
        case .missingLoginUrl:
            return NSLocalizedString("addSite.selfHosted.noLoginUrlFound", value: "Application Password authentication needs to be enabled on the WordPress site.", comment: "Error message shown when application-password authentication is disabled on a self-hosted WordPress site")
        case let .authenticationFailure(error):
            if error.code == .canceledLogin {
                return nil
            }
            fallthrough
        case .invalidApplicationPasswordCallback:
            return NSLocalizedString("addSite.selfHosted.authenticationFailed", value: "Cannot login using Application Password authentication.", comment: "Error message shown when an receiving an invalid application-password authentication result from a self-hosted WordPress site")
        case .loadingSiteInfoFailure:
            return NSLocalizedString("addSite.selfHosted.loadingSiteInfoFailure", value: "Cannot load the WordPress site details", comment: "Error message shown when failing to load details from a self-hosted WordPress site")
        case .savingSiteFailure:
            return NSLocalizedString("addSite.selfHosted.savingSiteFailure", value: "Cannot save the WordPress site, please try again later.", comment: "Error message shown when failing to save a self-hosted site to user's device")
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
    LoginWithUrlView(anchor: ASPresentationAnchor()) { _ in }
}
