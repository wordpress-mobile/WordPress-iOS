import Foundation
import WordPressAPI
import WordPressData

extension ApplicationPasswordService {
    /// Introspection and deletion must use one credential, without authentication refresh or replay.
    static func makeRevocationAPI(for site: WordPressSite) throws -> WordPressAPI {
        guard let credentials = site.applicationPasswordCredentials else {
            throw ApplicationPasswordDeletionError.unknownCurrentPassword
        }
        return WordPressAPI(
            urlSession: URLSession(configuration: .ephemeral),
            notifyingDelegate: PulseNetworkLogger.shared,
            siteInfo: .selfHosted(siteUrl: try ParsedUrl.from(url: site.siteURL), apiRoot: credentials.apiRootURL),
            authentication: .init(username: credentials.username, password: credentials.token),
            appNotifier: AppNotifier(site: site, coreDataStack: ContextManager.shared)
        )
    }
}
