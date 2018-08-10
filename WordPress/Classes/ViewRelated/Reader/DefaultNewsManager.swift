/** Default implementation of the NewsManager protocol.
 * The card is shown if it has not been dismissed yet
 * AND
 * The card is shown on the first Reader filter that users navigate to
 * AND
 * If users navigate to another Reader filter, or another screen, the card disappears, but if they navigate back to the filter where it was presented first, it’ll be visible again
 * AND
 * If users tap dismiss, the card disappears and will never be displayed again for the same app version
 */
final class DefaultNewsManager: NewsManager {
    private enum DatabaseKeys {
        static let lastDismissedCardVersion = "com.wordpress.newscard.last-dismissed-card-version"
        static let cardContainerIdentifier = "com.wordpress.newscard.cardcontaineridentifier"
    }

    private let service: NewsService
    private let database: KeyValueDatabase

    private var result: Result<NewsItem>?

    init(service: NewsService, database: KeyValueDatabase) {
        self.service = service
        self.database = database
        load()
    }

    func dismiss() {
        deactivateCurrentCard()
    }

    func readMore() {
        guard let actualResult = result else {
            return
        }

        switch actualResult {
        case .success(let value):
            UniversalLinkRouter.shared.handle(url: value.extendedInfoURL)
        case .error:
            return
        }
    }

    func shouldPresentCard(contextId: Identifier) -> Bool {
        return currentCardVersionIsGreaterThanLastDismissedCardVersion() && cardVersionMatchesBuild()
    }

    private func load() {
        service.load { [weak self] result in
            self?.result = result
        }
    }

    func load(then completion: @escaping (Result<NewsItem>) -> Void) {
        if let loadedResult = result {
            completion(loadedResult)
            return
        }

        service.load { [weak self] newResult in
            self?.result = newResult
            completion(newResult)
        }
    }

    private func cardVersionMatchesBuild() -> Bool {
        guard let actualResult = result else {
            return false
        }

        switch actualResult {
        case .success(let value):
            return currentBuildVersion() == value.version
        case .error:
            return false
        }
    }

    private func currentBuildVersion() -> Decimal? {
        guard let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            DDLogError("No CFBundleShortVersionString found in Info.plist")
            return nil
        }

        return Decimal(string: version)
    }

    private func currentCardVersion() -> Decimal {
        guard let actualResult = result else {
            return Decimal(floatLiteral: 0.0)
        }

        switch actualResult {
        case .error:
            return Decimal(floatLiteral: 0.0)
        case .success(let newsItem):
            return newsItem.version
        }
    }

    private func currentCardVersionIsGreaterThanLastDismissedCardVersion() -> Bool {
        guard let lastSavedVersion = database.object(forKey: DatabaseKeys.lastDismissedCardVersion) as? Decimal else {
            return true
        }

        return lastSavedVersion < currentCardVersion()
    }

    private func deactivateCurrentCard() {
        guard let actualResult = result else {
            return
        }

        switch actualResult {
        case .error:
            return
        case .success(let newsItem):
            database.set(newsItem.version, forKey: DatabaseKeys.lastDismissedCardVersion)
        }
    }
}
