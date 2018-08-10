/// Default implementation of the NewsManager protocol
final class DefaultNewsManager: NewsManager {
    private static let databaseKey = "com.wordpress.newscard.version"

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
    }

    func shouldPresentCard() -> Bool {
        return currentCardVersionIsGreaterThanSavedCardVersion() && cardVersionMatchesBuild()
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

    private func currentCardVersionIsGreaterThanSavedCardVersion() -> Bool {
        guard let lastSavedVersion = database.object(forKey: type(of: self).databaseKey) as? Decimal else {
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
            database.set(newsItem.version, forKey: type(of: self).databaseKey)
        }
    }
}
