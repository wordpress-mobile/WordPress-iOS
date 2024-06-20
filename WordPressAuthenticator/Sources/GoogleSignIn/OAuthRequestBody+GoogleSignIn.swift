extension OAuthTokenRequestBody {

    static func googleSignInRequestBody(
        clientId: GoogleClientId,
        audience: String,
        authCode: String,
        pkce: ProofKeyForCodeExchange
    ) -> Self {
        .init(
            clientId: clientId.value,
            // "The client secret obtained from the API Console Credentials page."
            // - https://developers.google.com/identity/protocols/oauth2/native-app#step-2:-send-a-request-to-googles-oauth-2.0-server
            //
            // There doesn't seem to be any secret for iOS app credentials.
            // The process works with an empty string...
            clientSecret: "",
            audience: audience,
            code: authCode,
            codeVerifier: pkce.codeVerifier,
            // As defined in the OAuth 2.0 specification, this field's value must be set to authorization_code.
            // – https://developers.google.com/identity/protocols/oauth2/native-app#exchange-authorization-code
            grantType: "authorization_code",
            redirectURI: clientId.defaultRedirectURI
        )
    }
}
