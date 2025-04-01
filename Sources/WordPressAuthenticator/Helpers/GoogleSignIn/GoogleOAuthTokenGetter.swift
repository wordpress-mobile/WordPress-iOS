class GoogleOAuthTokenGetter: GoogleOAuthTokenGetting {

    let dataGetter: DataGetting

    init(dataGetter: DataGetting = URLSession.shared) {
        self.dataGetter = dataGetter
    }

    func getToken(
        clientId: GoogleClientId,
        audience: String,
        authCode: String,
        pkce: ProofKeyForCodeExchange
    ) async throws -> OAuthTokenResponseBody {
        let request = try URLRequest.googleSignInTokenRequest(
            body: .googleSignInRequestBody(
                clientId: clientId,
                audience: audience,
                authCode: authCode,
                pkce: pkce
            )
        )

        let data = try await dataGetter.data(for: request)

        return try JSONDecoder().decode(OAuthTokenResponseBody.self, from: data)
    }
}
