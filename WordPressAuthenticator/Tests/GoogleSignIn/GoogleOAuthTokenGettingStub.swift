@testable import WordPressAuthenticator

struct GoogleOAuthTokenGettingStub: GoogleOAuthTokenGetting {

    let result: Result<OAuthTokenResponseBody, Error>

    init(response: OAuthTokenResponseBody) {
        self.init(result: .success(response))
    }

    init(error: Error) {
        self.init(result: .failure(error))
    }

    init(result: Result<OAuthTokenResponseBody, Error>) {
        self.result = result
    }

    func getToken(
        clientId: GoogleClientId,
        audience: String,
        authCode: String,
        pkce: ProofKeyForCodeExchange
    ) async throws -> OAuthTokenResponseBody {
        switch result {
        case .success(let response): return response
        case .failure(let error): throw error
        }
    }
}
