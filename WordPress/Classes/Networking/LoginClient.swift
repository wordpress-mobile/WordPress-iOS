import Foundation
import WordPressAPI
import AutomatticTracks
import ViewLayer
import SwiftUI
import AuthenticationServices
import WordPressKit
import WordPressAuthenticator

final actor LoginClient {

    static let callbackURLScheme = "x-wpcom-login"

    struct ApiDetails {
        let rootUrl: ParsedUrl
        let loginUrl: ParsedUrl
    }

    enum LoginClientError: Error {
        case invalidSiteAddress(UrlDiscoveryError)
        case missingLoginUrl
        case authenticationFailure(ASWebAuthenticationSessionError)
        case invalidApplicationPasswordCallback
        case loadingSiteInfoFailure
        case savingSiteFailure
        case unknown(error: Error)
    }

    private let internalClient: WordPressLoginClient

    init(session: URLSession) {
        self.internalClient = WordPressLoginClient(urlSession: session)
    }

    func performLoginAutodiscovery(for url: URL) async -> Result<ApiDetails, LoginClientError> {
        let result = await performLoginAutodiscovery(for: url.absoluteString)

        if case let .failure(error) = result {
            trackTypedError(error, url: url.absoluteString)
        }

        return result
    }

    private func performLoginAutodiscovery(for string: String) async -> Result<ApiDetails, LoginClientError> {
        let result: UrlDiscoverySuccess
        do {
            result = try await internalClient.discoverLoginUrl(for: string)
        } catch let error as UrlDiscoveryError {
            DDLogError("Discovery login url error: \(error)")
            return .failure(.invalidSiteAddress(error))
        } catch {
            DDLogError("Discovery login url error: \(error)")
            return .failure(.unknown(error: error))
        }

        // All sites should have some form of authentication we can use
        guard let passwordAuthenticationUrl = result.apiDetails.findApplicationPasswordsAuthenticationUrl(),
              let parsedLoginUrl = try? ParsedUrl.parse(input: passwordAuthenticationUrl) else {
            return .failure(.missingLoginUrl)
        }

        return .success(ApiDetails(rootUrl: result.apiRootUrl, loginUrl: parsedLoginUrl))
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

    func login(site: String, from anchor: ASPresentationAnchor?) async -> Result<WordPressOrgCredentials, LoginClientError> {
        let authURL = await buildLoginUrl(from: site)
        switch authURL {
        case let .success(authURL):
            let urlWithToken = await presentWebView(authURL: authURL, from: anchor)
            switch urlWithToken {
            case let .success(urlWithToken):
                return await handleAuthenticationCallback(urlWithToken)
            case let .failure(error):
                return .failure(error)
            }
        case let .failure(error):
            return .failure(error)
        }
    }

    @MainActor
    func buildLoginUrl(from userInput: String) async -> Result<URL, LoginClientError> {
        await self.performLoginAutodiscovery(for: userInput)
            .map { result in
                var mutableAuthURL = URL(string: result.loginUrl.url())!

                let appName = AppConfiguration.isJetpack ? "Jetpack iOS" : "WordPress iOS"
                let deviceName = UIDevice.current.name
                let timestamp = ISO8601DateFormatter.string(from: .now, timeZone: .current, formatOptions: .withInternetDateTime)
                let appNameValue = "\(appName) - \(deviceName) (\(timestamp))"

                mutableAuthURL.append(queryItems: [
                    URLQueryItem(name: "app_name", value: appNameValue),
                    URLQueryItem(name: "app_id", value: "00000000-0000-4000-8000-000000000000"),
                    URLQueryItem(name: "success_url", value: "\(Self.callbackURLScheme)://login-confirmation")
                ])

                return mutableAuthURL
            }
    }

    @MainActor
    func presentWebView(authURL: URL, from anchor: ASPresentationAnchor?) async -> Result<URL, LoginClientError> {
        debugPrint("Presenting Login Page \(authURL)")
        let contextProvider = SelfHostedLoginViewModelAuthenticationContextProvider(anchor: anchor ?? ASPresentationAnchor())
        return await withCheckedContinuation { continuation in
            let session = ASWebAuthenticationSession(url: authURL, callbackURLScheme: LoginClient.callbackURLScheme) { url, error in
                if let url {
                    continuation.resume(returning: .success(url))
                } else if let error = error as? ASWebAuthenticationSessionError {
                    continuation.resume(returning: .failure(.authenticationFailure(error)))
                } else {
                    continuation.resume(returning: .failure(.invalidApplicationPasswordCallback))
                }
            }
            session.presentationContextProvider = contextProvider
            session.start()
        }
    }

    func handleAuthenticationCallback(_ urlWithToken: URL) async -> Result<WordPressOrgCredentials, LoginClientError> {
        let credentials: SelfHostedLoginDetails
        do {
            credentials = try SelfHostedLoginDetails.fromApplicationPasswordResponse(urlWithToken)
        } catch {
            return .failure(.invalidApplicationPasswordCallback)
        }

        let blogOptions: [AnyHashable: Any]
        do {
            blogOptions = try await loadSiteOptions(details: credentials)
        } catch {
            return .failure(.loadingSiteInfoFailure)
        }

        // Only store the new site after credentials are validated.
        do {
            let _ = try await Blog.createRestApiBlog(with: credentials, in: ContextManager.shared)
        } catch {
            return .failure(.savingSiteFailure)
        }

        let wporg = WordPressOrgCredentials(
            username: credentials.username,
            password: credentials.password,
            xmlrpc: credentials.derivedXMLRPCRoot.absoluteString,
            options: blogOptions
        )
        return .success(wporg)
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

private class SelfHostedLoginViewModelAuthenticationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    let anchor: ASPresentationAnchor

    init(anchor: ASPresentationAnchor) {
        self.anchor = anchor
    }

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        anchor
    }
}
