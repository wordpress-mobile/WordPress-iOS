/// See https://developers.google.com/identity/openid-connect/openid-connect#obtainuserinfo
public struct IDToken {

    public let token: JSONWebToken
    public let name: String
    public let email: String

    // TODO: Validate token! – https://developers.google.com/identity/openid-connect/openid-connect#validatinganidtoken
    init?(jwt: JSONWebToken) {
        // Name and email might not be part of the JWT Google sent us if the scope used for the
        // request didn't include them
        guard let email = jwt.payload["email"] as? String else {
            return nil
        }
        guard let name = jwt.payload["name"] as? String else {
            return nil
        }

        self.token = jwt
        self.name = name
        self.email = email
    }
}
