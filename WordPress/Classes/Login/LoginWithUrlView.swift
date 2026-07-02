import SwiftUI
import AuthenticationServices
import WordPressAPI
import WordPressAPIInternal
import WordPressData
import DesignSystem
import WordPressShared
import WordPressUI

struct LoginWithUrlView: View {

    weak var presenter: UIViewController?
    let loginCompleted: (TaggedManagedObjectID<Blog>) -> Void
    let presentDotComLogin: () -> Void

    @State fileprivate var errorMessage: String?
    @State private var urlField: String = ""
    @State private var isLoading = false
    // 0 or negative values cancels the login attempt. Positive values kick off a new login attempt.
    @State private var loginTrigger = 0

    @Environment(\.dismiss) var dismiss

    private var isContinueButtonDisabled: Bool {
        isLoading || urlField.trim().isEmpty
    }

    var body: some View {
        VStack(alignment: .leading) {
            Image("splashLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 60, height: 60)
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .center)

            Text(Strings.enterSiteAddress)

            siteAdddressTextField()

            if let errorMessage {
                errorSection(errorMessage)
            }

            Spacer()

            DSButton(
                title: SharedStrings.Button.continue,
                style: DSButtonStyle(emphasis: .primary, size: .large),
                isLoading: .constant(isLoading),
                action: { self.loginTrigger += 1 }
            )
            .disabled(isContinueButtonDisabled)
            .accessibilityIdentifier("Site Address Next Button")
        }
        .padding()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(SharedStrings.Button.cancel) {
                    // Updating `loginTrigger` to explicitly cancel the login task.
                    // `dismiss` is not sufficient, probably because the `LoginWithUrlView`
                    // is presented as a UIKit view.
                    loginTrigger = 0
                    dismiss()
                }
            }
        }
        .task(id: loginTrigger) {
            guard loginTrigger > 0 else { return }
            await startLogin()
        }
        .navigationTitle(Strings.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func errorSection(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(message)
                .foregroundStyle(.red)
            Button(Strings.contactSupport) {
                contactSupportTapped()
            }
            .font(.subheadline.weight(.medium))
        }
    }

    private func contactSupportTapped() {
        guard let presenter else {
            wpAssertionFailure("No presenter assigned")
            return
        }
        // The `presenter` sits below the sheet hosting this view, so present
        // the support screen from the topmost view controller instead.
        let supportViewController = SupportTableViewController()
        supportViewController.show(from: presenter.topmostPresentedViewController)
    }

    private func siteAdddressTextField() -> some View {
        HStack {
            TextField(text: $urlField) {
                Text("example.com")
            }
            .accessibilityIdentifier("Site address")

            if !urlField.isEmpty {
                Button {
                    urlField = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.gray)
                }
            }
        }
        .padding(.top)
        .padding(.bottom, 8)
        .overlay(alignment: .bottom) { Divider() }
        .overlay(Divider(), alignment: .bottom)
        .tint(.green)
        .textContentType(.URL)
        .keyboardType(.URL)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .onSubmit { self.loginTrigger += 1 }
        .disabled(isLoading)
    }

    private func startLogin() async {
        guard let presenter else {
            wpAssertionFailure("No presenter assigned")
            return
        }

        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        let details: AutoDiscoveryAttemptSuccess
        do {
            let loginClient = WordPressLoginClient(urlSession: URLSession(configuration: .ephemeral))
            details = try await loginClient.details(ofSite: urlField)
        } catch is CancellationError {
            return
        } catch {
            errorMessage = error.localizedDescription
            return
        }

        if Task.isCancelled { return }

        if case let .oAuth2(endpoints) = details.authentication,
            endpoints.authorizationUrl.contains("public-api.wordpress.com")
        {
            presenter.dismiss(animated: true) {
                Notice(title: Strings.wpcomSiteRedirect).post()
                presentDotComLogin()
            }
            return
        }

        do {
            let blog = try await SelfHostedSiteAuthenticator()
                .signIn(details: details, from: presenter, context: .default)
            dismiss()
            self.loginCompleted(blog)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private enum Strings {
    static let title = NSLocalizedString(
        "addSite.selfHosted.title",
        value: "Add Self-Hosted Site",
        comment: "Title of the page to add a self-hosted site"
    )

    static let enterSiteAddress = NSLocalizedString(
        "addSite.selfHosted.enterSiteAddress",
        value: "Enter the address of the WordPress site you'd like to connect.",
        comment: "A message to inform users to type the site address in the text field."
    )

    static let wpcomSiteRedirect = NSLocalizedString(
        "addSite.selfHosted.wpcomSiteRedirect",
        value: "This site is hosted on WordPress.com. Please log in with your WordPress.com account.",
        comment: "Notice message shown when a user tries to add a WordPress.com site as self-hosted"
    )

    static let contactSupport = NSLocalizedString(
        "addSite.selfHosted.contactSupport",
        value: "Contact Support",
        comment: "Button to contact support, shown when signing in to a self-hosted site fails"
    )
}

// MARK: - SwiftUI Preview

extension LoginWithUrlView {
    /// Preview-only convenience to force the error state.
    fileprivate init(errorMessage: String?, urlField: String) {
        self.presenter = nil
        self.loginCompleted = { _ in }
        self.presentDotComLogin = {}
        self._errorMessage = State(initialValue: errorMessage)
        self._urlField = State(initialValue: urlField)
    }
}

#Preview("Default") {
    NavigationStack {
        LoginWithUrlView(
            presenter: nil,
            loginCompleted: { _ in },
            presentDotComLogin: {}
        )
    }
}

#Preview("Sign-in failed") {
    NavigationStack {
        LoginWithUrlView(
            errorMessage:
                "We couldn't log in to your site. The site at mysite.example.com doesn't appear to have the REST API enabled.",
            urlField: "mysite.example.com"
        )
    }
}
