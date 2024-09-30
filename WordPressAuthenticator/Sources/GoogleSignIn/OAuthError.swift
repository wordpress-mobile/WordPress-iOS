public enum OAuthError: LocalizedError {

    // ASWebAuthenticationSession
    case inconsistentWebAuthenticationSessionCompletion

    case failedToGenerateSecureRandomCodeVerifier(status: Int32)

    // OAuth token response
    case urlDidNotContainCodeParameter(url: URL)
    case tokenResponseDidNotIncludeIdToken

    public var errorDescription: String {
        switch self {
        case .inconsistentWebAuthenticationSessionCompletion:
            return "ASWebAuthenticationSession authentication finished with neither a callback URL nor error"
        case .failedToGenerateSecureRandomCodeVerifier(let status):
            return "Could not generate a cryptographically secure random PKCE code verifier value. Underlying error code \(status)"
        case .urlDidNotContainCodeParameter(let url):
            return "Could not find 'code' parameter in URL '\(url)'"
        case .tokenResponseDidNotIncludeIdToken:
            return "OAuth token response did not include idToken"
        }
    }
}
