// See:
// - https://developers.google.com/identity/protocols/oauth2/native-app#step1-code-verifier
// - https://www.rfc-editor.org/rfc/rfc7636
//
// Note: The common abbreviation of "Proof Key for Code Exchange" is PKCE and is pronounced "pixy".
struct ProofKeyForCodeExchange: Equatable {

    enum Method: Equatable {
        case s256
        case plain

        var urlQueryParameterValue: String {
            switch self {
            case .plain: return "plain"
            case .s256: return "S256"
            }
        }
    }

    let codeVerifier: CodeVerifier
    let method: Method

    init() throws {
        self.codeVerifier = try .makeRandomCodeVerifier()
        self.method = .s256
    }

    init(codeVerifier: CodeVerifier, method: Method) {
        self.codeVerifier = codeVerifier
        self.method = method
    }

    var codeChallenge: String {
        codeVerifier.codeChallenge(using: method)
    }
}

extension ProofKeyForCodeExchange {

    // A code_verifier is a high-entropy cryptographic random string using the unreserved
    // characters [A-Z] / [a-z] / [0-9] / "-" / "." / "_" / "~", with a minimum length of 43
    // characters and a maximum length of 128 characters.
    //
    // The code verifier should have enough entropy to make it impractical to guess the value.
    //
    // See:
    // - https://www.rfc-editor.org/rfc/rfc7636#section-4.1
    // - https://developers.google.com/identity/protocols/oauth2/native-app#step1-code-verifier
    struct CodeVerifier: Equatable {

        let rawValue: String

        static let allowedCharacters = Character.urlSafeCharacters
        static let allowedLengthRange = (43...128)

        /// Generates a random code verifier according to the PKCE RFC.
        ///
        /// - Note: This method name is more verbose than the recommended "make<Type>" for this factory to communicate the randomness component.
        static func makeRandomCodeVerifier() throws -> Self {
            let value = try randomSecureCodeVerifier()

            // It's appropriate to force unwrap here because a `nil` value could only result from
            // a developer error—either wrong coding of the constrained length or of the allowed
            // characters.
            return .init(value: value)!
        }

        init?(value: String) {
            guard CodeVerifier.allowedLengthRange.contains(value.count) else { return nil }

            guard Set(value).isSubset(of: CodeVerifier.allowedCharacters) else { return nil }

            self.rawValue = value
        }

        func codeChallenge(using method: Method) -> String {
            switch method {
            case .s256:
                // The spec defines code_challenge for the s256 mode as:
                //
                // code_challenge = BASE64URL-ENCODE(SHA256(ASCII(code_verifier)))
                //
                // We don't need the ASCII conversion, because we build `CodeVerifier` from URL safe
                // characters.
                let rawData = Data(rawValue.utf8)
                let hashedData: Data = rawData.sha256Hashed()
                return hashedData.base64URLEncodedString()
            case .plain:
                return rawValue
            }
        }
    }

    /// Generates a random code verifier according to the PKCE RFC.
    ///
    /// The RFC states:
    ///
    /// > It is RECOMMENDED that the output of a suitable random number generator be used to create a 32-octet sequence.
    /// > The octet sequence is then base64url-encoded to produce a 43-octet URL safe string to use as the code verifier.
    static func randomSecureCodeVerifier() throws -> String {
        let byteCount = 32
        var bytes = [UInt8](repeating: 0, count: byteCount)
        let result = SecRandomCopyBytes(kSecRandomDefault, byteCount, &bytes)

        guard result == errSecSuccess else {
            throw OAuthError.failedToGenerateSecureRandomCodeVerifier(status: result)
        }

        let data = Data(bytes)

        // Base64url-encoding a 32-octect sequence should always result in a 43-length string,
        // string, but let's cap it just in case.
        //
        // Also notice that by base64url-encoding, we ensure the characters are in the allowed
        // set.
        //
        // 43 is also the minimum length for a code verifier, hence the `allowedLengthRange.lowerBound` usage.
        return String(data.base64URLEncodedString().prefix(CodeVerifier.allowedLengthRange.lowerBound))
    }
}
