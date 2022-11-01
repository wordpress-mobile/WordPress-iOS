protocol CredentialsProvider {
    func getPassword(username: String, service: String) -> String?
}

struct KeychainCredentialsProvider: CredentialsProvider {
    func getPassword(username: String, service: String) -> String? {
        return try? SFHFKeychainUtils.getPasswordForUsername(username, andServiceName: service)
    }
}

class CredentialsService {
    private let provider: CredentialsProvider
    private let dotComOAuthKeychainService = "public-api.wordpress.com"

    init(provider: CredentialsProvider = KeychainCredentialsProvider()) {
        self.provider = provider
    }

    func getOAuthToken(site: JetpackSiteRef) -> String? {
        return provider.getPassword(username: site.username, service: dotComOAuthKeychainService)
    }
}
