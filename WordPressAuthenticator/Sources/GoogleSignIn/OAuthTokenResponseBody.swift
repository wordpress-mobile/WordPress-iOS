/// Models the response to an OAuth token request.
///
/// - Note: See documentation at https://developers.google.com/identity/protocols/oauth2/native-app#exchange-authorization-code
struct OAuthTokenResponseBody: Codable, Equatable {
    let accessToken: String
    let expiresIn: Int
    /// This value is only returned if the request included an identity scope, such as openid, profile, or email.
    /// The value is a JSON Web Token (JWT) that contains digitally signed identity information about the user.
    let rawIDToken: String?
    let refreshToken: String?
    let scope: String
    /// The type of token returned. At this time, this field's value is always set to Bearer.
    let tokenType: String

    var idToken: IDToken? {
        guard let rawIDToken = rawIDToken else {
            return nil
        }

        guard let jwt = JSONWebToken(encodedString: rawIDToken) else {
            return nil
        }

        return IDToken(jwt: jwt)
    }

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
        case rawIDToken = "id_token"
        case refreshToken = "refresh_token"
        case scope
        case tokenType = "token_type"
    }
}
