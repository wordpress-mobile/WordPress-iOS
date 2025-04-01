public struct GoogleClientId {

    let value: String

    public init?(string: String) {
        guard string.split(separator: ".").count > 1 else {
            return nil
        }
        self.value = string
    }

    /// See https://developers.google.com/identity/protocols/oauth2/native-app#step1-code-verifier
    func redirectURI(path: String?) -> String {
        let root = value.split(separator: ".").reversed().joined(separator: ".")

        guard let path else {
            return root
        }

        return "\(root):/\(path)"
    }

    var defaultRedirectURI: String {
        redirectURI(path: "oauth2callback")
    }
}
