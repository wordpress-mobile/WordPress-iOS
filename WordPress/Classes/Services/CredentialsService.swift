import BuildSettingsKit
import WordPressShared

protocol CredentialsProvider {
    func getPassword(username: String, service: String) -> String?
}

struct KeychainCredentialsProvider: CredentialsProvider {
    func getPassword(username: String, service: String) -> String? {
        try? AppKeychain().getPassword(for: username, serviceName: service)
    }
}

class CredentialsService {
    private let provider: CredentialsProvider

    init(provider: CredentialsProvider = KeychainCredentialsProvider()) {
        self.provider = provider
    }

    func getOAuthToken(site: JetpackSiteRef) -> String? {
        provider.getPassword(username: site.username, service: BuildSettings.current.authKeychainServiceName)
    }
}
