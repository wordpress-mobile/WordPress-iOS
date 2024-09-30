protocol GoogleOAuthTokenGetting {

    func getToken(
        clientId: GoogleClientId,
        audience: String,
        authCode: String,
        pkce: ProofKeyForCodeExchange
    ) async throws -> OAuthTokenResponseBody
}
