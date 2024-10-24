import AuthenticationServices
import Foundation
import UIKit

import Alamofire

/// Log in or sign up a WordPress.com account via web.
///
/// API doc: https://developer.wordpress.com/docs/oauth2/
struct WordPressDotComAuthenticator {
    enum Error: Swift.Error {
        case invalidCallbackURL
        case obtainAccessToken
        case urlError(URLError)
        case parsing(DecodingError)
        case cancelled
        case unknown(Swift.Error)
    }

    func authenticate(from viewController: UIViewController) async throws -> String {
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
        guard let query = URLComponents(url: url, resolvingAgainstBaseURL: true)?.queryItems,
              let code = query.first(where: { $0.name == "code" })?.value else {
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
