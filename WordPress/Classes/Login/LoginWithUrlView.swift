import SwiftUI
import AuthenticationServices
import WordPressAPI
import WordPressAuthenticator
import WordPressData
import DesignSystem
import WordPressShared

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
                Text(errorMessage)
                    .foregroundStyle(.red)
            }

            Spacer()

            DSButton(
                title: SharedStrings.Button.continue,
                style: DSButtonStyle(emphasis: .primary, size: .large),
                isLoading: .constant(isLoading),
                action: { self.loginTrigger += 1 }
            )
            .disabled(isContinueButtonDisabled)
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

    private func siteAdddressTextField() -> some View {
        HStack {
            TextField(text: $urlField) {
                Text("example.com")
            }

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

        do {
            let blog = try await SelfHostedSiteAuthenticator()
                .signIn(site: urlField, from: presenter, context: .default)

            dismiss()
            self.loginCompleted(blog)
        } catch {
            if await shouldRedirectToDotComLogin(error: error) {
                // We need to chain the dismissing and presenting,
                // which is not supported by SwiftUI's `dismiss` variable.
                presenter.dismiss(animated: true) {
                    Notice(title: Strings.wpcomSiteRedirect).post()
                    presentDotComLogin()
                }
            } else {
                errorMessage = error.localizedDescription
            }
        }
    }

    // If the error is "API root (wp-json) not found", it's possible that the user typed
    // a WP.com simple site address. We should redirect to WP.com login if that's
    // the case.
    private func shouldRedirectToDotComLogin(
        error: SelfHostedSiteAuthenticator.SignInError
    ) async -> Bool {
        guard case let .authentication(error) = error,
              let error = error as? AutoDiscoveryAttemptFailure,
              error.shouldAttemptDotComLogin else { return false}

        let api = WordPressComRestApi.anonymousApi(userAgent: WPUserAgent.defaultUserAgent())
        let remote = BlogServiceRemoteREST(wordPressComRestApi: api, siteID: 0)
        let url = WordPressAuthenticator.baseSiteURL(string: urlField)
        let response: [AnyHashable: Any]? = await withCheckedContinuation { continuation in
            remote.fetchUnauthenticatedSiteInfo(forAddress: url) {
                continuation.resume(returning: $0)
            } failure: { _ in
                continuation.resume(returning: nil)
            }
        }
        return (response?["isWordPressDotCom"] as? Bool) == true
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
}

private extension AutoDiscoveryAttemptFailure {
    var shouldAttemptDotComLogin: Bool {
        switch self {
        case .ParseSiteUrl:
            false
        case .FindApiRoot, .FetchAndParseApiRoot:
            true
        }
    }
}

// MARK: - SwiftUI Preview

#Preview {
    LoginWithUrlView(
        presenter: nil,
        loginCompleted: { _ in },
        presentDotComLogin: { }
    )
}
