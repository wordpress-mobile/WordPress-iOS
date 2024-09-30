import AuthenticationServices

public class NewGoogleAuthenticator: NSObject {

    let clientId: GoogleClientId
    let scheme: String
    let audience: String
    let oauthTokenGetter: GoogleOAuthTokenGetting

    public convenience init(
        clientId: GoogleClientId,
        scheme: String,
        audience: String,
        urlSession: URLSession
    ) {
        self.init(
            clientId: clientId,
            scheme: scheme,
            audience: audience,
            oautTokenGetter: GoogleOAuthTokenGetter(dataGetter: urlSession)
        )
    }

    init(
        clientId: GoogleClientId,
        scheme: String,
        audience: String,
        oautTokenGetter: GoogleOAuthTokenGetting
    ) {
        self.clientId = clientId
        self.scheme = scheme
        self.audience = audience
        self.oauthTokenGetter = oautTokenGetter
    }

    /// Get the user's OAuth token from their Google account. This token can be used to authenticate with the WordPress backend.
    ///
    /// The app will present the browser to hand over authentication to Google from the given `UIViewController`.
    public func getOAuthToken(from viewController: UIViewController) async throws -> IDToken {
        return try await getOAuthToken(
            from: WebAuthenticationPresentationContext(viewController: viewController)
        )
    }

    /// Get the user's OAuth token from their Google account. This token can be used to authenticate with the WordPress backend.
    ///
    /// The app will present the browser to hand over authentication to Google using the given
    /// `ASWebAuthenticationPresentationContextProviding`.
    public func getOAuthToken(
        from contextProvider: ASWebAuthenticationPresentationContextProviding
    ) async throws -> IDToken {
        let pkce = try ProofKeyForCodeExchange()
        let url = try await getURL(
            clientId: clientId,
            scheme: scheme,
            pkce: pkce,
            contextProvider: contextProvider
        )
        return try await requestOAuthToken(url: url, clientId: clientId, audience: audience, pkce: pkce)
    }

    func getURL(
        clientId: GoogleClientId,
        scheme: String,
        pkce: ProofKeyForCodeExchange,
        contextProvider: ASWebAuthenticationPresentationContextProviding
    ) async throws -> URL {
        let url = try URL.googleSignInAuthURL(clientId: clientId, pkce: pkce)
        return try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: scheme,
                completionHandler: { result in
                    continuation.resume(with: result)
                }
            )

            session.presentationContextProvider = contextProvider
            // At this point in time, we don't see the need to make the session ephemeral.
            //
            // Additionally, from a user's perspective, it would be frustrating to have to
            // authenticate with Google again unless necessary—it certainly would be when testing
            // the app.
            session.prefersEphemeralWebBrowserSession = false

            // It feels inappropriate to force a dispatch on the main queue deep within the library.
            // However, this is required to ensure `session` accesses the view it needs for the presentation on the right thread.
            //
            // See tradeoffs consideration at:
            // https://github.com/wordpress-mobile/WordPressAuthenticator-iOS/pull/743#discussion_r1109325159
            DispatchQueue.main.async {
                session.start()
            }
        }
    }

    func requestOAuthToken(
        url: URL,
        clientId: GoogleClientId,
        audience: String,
        pkce: ProofKeyForCodeExchange
    ) async throws -> IDToken {
        guard let authCode = URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first(where: { $0.name == "code" })?
            .value else {
            throw OAuthError.urlDidNotContainCodeParameter(url: url)
        }

        let response = try await oauthTokenGetter.getToken(
            clientId: clientId,
            audience: audience,
            authCode: authCode,
            pkce: pkce
        )

        guard let idToken = response.idToken else {
            throw OAuthError.tokenResponseDidNotIncludeIdToken
        }

        return idToken
    }
}
