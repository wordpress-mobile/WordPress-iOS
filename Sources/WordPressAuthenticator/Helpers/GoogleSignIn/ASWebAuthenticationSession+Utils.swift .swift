import AuthenticationServices

extension ASWebAuthenticationSession {

    /// Wrapper around the default `init(url:, callbackULRScheme:, completionHandler:)` where the
    /// `completionHandler` argument is a `Result<URL, Error>` instead of a `URL` and `Error` pair.
    convenience init(url: URL, callbackURLScheme: String, completionHandler: @escaping (Result<URL, Error>) -> Void) {
        self.init(url: url, callbackURLScheme: callbackURLScheme) { callbackURL, error in
            completionHandler(
                Result(
                    value: callbackURL,
                    error: error,
                    // Unfortunately we cannot exted `ASWebAuthenticationSessionError.Code` to add
                    // a custom error for this scenario, so we're left to use a "generic" one.
                    inconsistentStateError: OAuthError.inconsistentWebAuthenticationSessionCompletion
                )
            )
        }
    }
}
