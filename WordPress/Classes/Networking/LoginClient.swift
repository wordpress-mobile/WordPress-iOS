import Foundation
import WordPressAPI
import AutomatticTracks
import ViewLayer
import SwiftUI
import AuthenticationServices
import WordPressKit
import WordPressAuthenticator

actor LoginClient {

    struct ApiDetails {
        let rootUrl: ParsedUrl
        let loginUrl: ParsedUrl
    }

    enum LoginClientError: Error {
        case missingLoginUrl
    }

    private let internalClient: WordPressLoginClient

    init(session: URLSession) {
        self.internalClient = WordPressLoginClient(urlSession: session)
    }

    func performLoginAutodiscovery(for url: URL) async throws -> ApiDetails {
        try await performLoginAutodiscovery(for: url.absoluteString)
    }

    func performLoginAutodiscovery(for string: String) async throws -> ApiDetails {
        do {
            let result = try await internalClient.discoverLoginUrl(for: string)
            trackSuccess(url: string)

            // All sites should have some form of authentication we can use
            guard let passwordAuthenticationUrl = result.apiDetails.findApplicationPasswordsAuthenticationUrl() else {
                throw LoginClientError.missingLoginUrl
            }

            let details = ApiDetails(
                rootUrl: result.apiRootUrl,
                loginUrl: try ParsedUrl.parse(input: passwordAuthenticationUrl)
            )

            return details
        }
        catch let error as LoginClientError { // We can have nicer logging for typed errors
            trackTypedError(error, url: string)
            throw error
        }
        catch {
            await WordPressAppDelegate.crashLogging?.logError(error) // This might result in a *lot* of errors...
            trackError(error, url: string)
            throw error
        }
    }

    private func trackSuccess(url: String) {
        WPAnalytics.track(.performedUrlDiscovery, properties: [
            "url": url,
            "success": true
        ])
    }

    private func trackError(_ error: Error, url: String) {
        DDLogError("Unable to login to \(url): \(error.localizedDescription)")

        WPAnalytics.track(.performedUrlDiscovery, properties: [
            "url": url,
            "success": false
        ])
    }

    private func trackTypedError(_ error: LoginClient.LoginClientError, url: String) {
        DDLogError("Unable to login to \(url): \(error.localizedDescription)")

        WPAnalytics.track(.performedUrlDiscovery, properties: [
            "url": url,
            "success": false,
            "error": error.localizedDescription
        ])
    }

    @MainActor
    static func displaySelfHostedLoginView(in navigationController: UINavigationController) {
        let loginClient = LoginClient(session: .shared)
        let vm = SelfHostedLoginViewModel(loginClient: loginClient)
        let loginViewController = UIHostingController(rootView: LoginWithUrlView(viewModel: vm))

        vm.onLoginComplete = { [weak loginViewController] in
            loginViewController?.dismiss(animated: true)
        }

        navigationController.pushViewController(loginViewController, animated: true)
    }
}

class SelfHostedLoginViewModel: LoginWithUrlView.ViewModel {
    private let loginClient: LoginClient
    private let presentationContextProvider = SelfHostedLoginViewModelAuthenticationContextProvider()

    var onLoginComplete: (() -> Void)?

    init(loginClient: LoginClient) {
        self.loginClient = loginClient
        super.init()
    }

    override func startLogin() {
        debugPrint("Attempting login with \(super.urlField)")
        Task {
            do {
                let authUrl = try await self.buildLoginUrl(from: super.urlField)
                debugPrint("Presenting Login Page \(authUrl)")

                let urlWithToken = try await withUnsafeThrowingContinuation { continuation in
                    let session = ASWebAuthenticationSession(url: authUrl, callbackURLScheme: "x-wpcom-login") { url, error in

                        if let url {
                            continuation.resume(returning: url)
                        }

                        if let error {
                            continuation.resume(throwing: error)
                        }
                    }
                    session.presentationContextProvider = self.presentationContextProvider
                    session.start()
                }

                let credentials = try SelfHostedLoginDetails.fromApplicationPasswordResponse(urlWithToken)
                let blogOptions = try await loadSiteOptions(details: credentials)

                // Only store the new site after credentials are validated.
                let _ = try await Blog.createRestApiBlog(with: credentials, in: ContextManager.shared)

                // Automatically show the new site.
                assert(WordPressAuthenticator.shared.delegate != nil)
                let wporg = WordPressOrgCredentials(
                    username: credentials.username,
                    password: credentials.password,
                    xmlrpc: credentials.derivedXMLRPCRoot.absoluteString,
                    options: blogOptions
                )
                WordPressAuthenticator.shared.delegate!.sync(credentials: .init(wporg: wporg)) {
                    NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: WordPressAuthenticator.WPSigninDidFinishNotification), object: nil)
                }

                self.onLoginComplete?()
            } catch let err {
                debugPrint(err.localizedDescription)
            }
        }
    }

    private func buildLoginUrl(from userInput: String) async throws -> URL {
        let result = try await self.loginClient.performLoginAutodiscovery(for: userInput)
        var mutableAuthURL = URL(string: result.loginUrl.url())!

        let appName = AppConfiguration.isJetpack ? "Jetpack iOS" : "WordPress iOS"
        let deviceName = await UIDevice.current.name
        let timestamp = ISO8601DateFormatter.string(from: Date(), timeZone: .current)
        let appNameValue = "\(appName) - \(deviceName) (\(timestamp))"

        mutableAuthURL.append(queryItems: [
            URLQueryItem(name: "app_name", value: appNameValue),
            URLQueryItem(name: "app_id", value: "00000000-0000-4000-8000-000000000000"),
            URLQueryItem(name: "success_url", value: "x-wpcom-login://login-confirmation")
        ])

        return mutableAuthURL
    }

    private func loadSiteOptions(details: SelfHostedLoginDetails) async throws -> [AnyHashable: Any] {
        try await withCheckedThrowingContinuation { continuation in
            let api = WordPressXMLRPCAPIFacade()
            api.getBlogOptions(withEndpoint: details.derivedXMLRPCRoot, username: details.username, password: details.password) { options in
                continuation.resume(returning: options ?? [:])
            } failure: { error in
                continuation.resume(throwing: error ?? Blog.BlogCredentialsError.incorrectCredentials)
            }
        }
    }
}

class SelfHostedLoginViewModelAuthenticationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        ASPresentationAnchor()
    }
}
