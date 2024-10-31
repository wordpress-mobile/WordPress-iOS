import AuthenticationServices
import Foundation
import UIKit
import WordPressAuthenticator

import Alamofire

/// Log in or sign up a WordPress.com account via web.
///
/// API doc: https://developer.wordpress.com/docs/oauth2/
struct WordPressDotComAuthenticator {
    enum Error: Swift.Error {
        case invalidCallbackURL
        case loginDenied(message: String)
        case obtainAccessToken
        case urlError(URLError)
        case parsing(DecodingError)
        case cancelled
        case unknown(Swift.Error)
    }

    @MainActor
    func signIn(from viewController: UINavigationController) async {
        let token: String
        do {
            token = try await authenticate(from: viewController)
        } catch {
            if let error = error as? WordPressDotComAuthenticator.Error {
                presentSignInError(error, from: viewController)
            } else {
                wpAssertionFailure("WP.com web login failed", userInfo: ["error": "\(error)"])
            }
            return
        }

        let delegate = WordPressAuthenticator.shared.delegate!
        let credentials = AuthenticatorCredentials(wpcom: WordPressComCredentials(authToken: token, isJetpackLogin: false, multifactor: false))
        SVProgressHUD.show()
        delegate.sync(credentials: credentials) {
            SVProgressHUD.dismiss()

            delegate.presentLoginEpilogue(
                in: viewController,
                for: credentials,
                source: .custom(source: "web-login"),
                onDismiss: { /* Do nothing */ }
            )
        }
    }

    private func presentSignInError(_ error: WordPressDotComAuthenticator.Error, from viewController: UIViewController) {
        // Show an alert for non-cancellation errors.
        let alertMessage: String
        switch error {
        case .cancelled:
            // `.cancelled` error is thrown when user taps the cancel button in the presented Safari view controller.
            // No need to show an alert for this error.
            return
        case let .loginDenied(message):
            alertMessage = message
        case let .urlError(error):
            alertMessage = error.localizedDescription
        case .invalidCallbackURL, .obtainAccessToken, .parsing, .unknown:
            // These errors are unexpected.
            wpAssertionFailure("WP.com web login failed", userInfo: ["error": "\(error)"])
            alertMessage = SharedStrings.Error.generic
        }

        let alert = UIAlertController(
            title: NSLocalizedString("generic.error.title", value: "Error", comment: "A generic title for an error"),
            message: alertMessage,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: SharedStrings.Button.close, style: .cancel, handler: nil))
        viewController.present(alert, animated: true)
    }

    func authenticate(from viewController: UIViewController) async throws -> String {
        WPAnalytics.track(.wpcomWebSignIn, properties: ["stage": "start"])

        do {
            let value = try await _authenticate(from: viewController)
            WPAnalytics.track(.wpcomWebSignIn, properties: ["stage": "success"])
            return value
        } catch {
            WPAnalytics.track(.wpcomWebSignIn, properties: ["stage": "error", "error": "\(error)"])
            throw error
        }
    }

    private func _authenticate(from viewController: UIViewController) async throws -> String {
        let clientId = ApiCredentials.client
        let clientSecret = ApiCredentials.secret
        let redirectURI = "x-wordpress-app://oauth2-callback"

        let authorizeURL = URL(string: "https://public-api.wordpress.com/oauth2/authorize")!
            .appending(queryItems: [
                URLQueryItem(name: "client_id", value: clientId),
                URLQueryItem(name: "redirect_uri", value: redirectURI),
                URLQueryItem(name: "response_type", value: "code"),
                URLQueryItem(name: "scope", value: "global"),
            ])

        let callbackURL: URL = try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async {
                let provider = WebAuthenticationPresentationAnchorProvider(anchor: viewController.view.window ?? UIWindow())
                let session = ASWebAuthenticationSession(url: authorizeURL, callbackURLScheme: "x-wordpress-app") { url, error in
                    if let url {
                        continuation.resume(returning: url)
                    } else {
                        DDLogWarn("Error from authentication session: \(String(describing: error))")
                        continuation.resume(throwing: Error.cancelled)
                    }
                }
                session.presentationContextProvider = provider
                session.start()
            }
        }

        return try await handleAuthorizeCallbackURL(callbackURL, clientId: clientId, clientSecret: clientSecret, redirectURI: redirectURI)
    }

    private func handleAuthorizeCallbackURL(
        _ url: URL,
        clientId: String,
        clientSecret: String,
        redirectURI: String
    ) async throws -> String {
        guard let query = URLComponents(url: url, resolvingAgainstBaseURL: true)?.queryItems else {
            throw Error.invalidCallbackURL
        }

        let queryMap: [String: String] = query.reduce(into: [:]) { $0[$1.name] = $1.value }

        guard let code = queryMap["code"] else {
            if queryMap["error"] == "access_denied" {
                let message = NSLocalizedString("wpComLogin.error.accessDenied", value: "Access denied. You need to approve to log in to WordPress.com", comment: "Error message when user denies access to WordPress.com")
                throw Error.loginDenied(message: message)
            }
            throw Error.invalidCallbackURL
        }

        var tokenRequest = URLRequest(url: URL(string: "https://public-api.wordpress.com/oauth2/token")!)
        tokenRequest.httpMethod = "POST"
        let parameters: [String: String] = [
            "grant_type": "authorization_code",
            "client_id": clientId,
            "client_secret": clientSecret,
            "redirect_uri": redirectURI,
            "code": code,
        ]

        do {
            tokenRequest = try URLEncodedFormParameterEncoder().encode(parameters, into: tokenRequest)
        } catch {
            wpAssertionFailure("Unexpected form encoding error", userInfo: ["error": "\(error)"])
            throw Error.unknown(error)
        }

        do {
            let urlSession = URLSession.shared
            let (data, _) = try await urlSession.data(for: tokenRequest)

            struct Response: Decodable {
                var accessToken: String
            }

            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let token = try decoder.decode(Response.self, from: data).accessToken

            return token
        } catch let error as URLError {
            throw Error.urlError(error)
        } catch let error as DecodingError {
            throw Error.parsing(error)
        } catch {
            DDLogError("Failed to parse token request response: \(error)")
            throw Error.unknown(error)
        }
    }
}
