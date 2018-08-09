/// Default implementation of the NewsManager protocol
final class DefaultNewsManager: NewsManager {
    private let service: NewsService
    private var result: Result<NewsItem>?

    init(service: NewsService) {
        self.service = service
        load()
    }

    func dismiss() {
    }

    func readMore() {
    }

    func shouldPresentCard() -> Bool {
        print("matching build ==== ", cardVersionMatchesBuild())
        return true
//        guard cardVersionMatchesBuild() else {
//            return false
//        }
//
//        return !cardWasDismissed()
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
            return currentVersion() == value.version
        case .error:
            return false
        }
    }

    private func currentVersion() -> Decimal? {
        guard let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            DDLogError("No CFBundleShortVersionString found in Info.plist")
            return nil
        }

        return Decimal(string: version)
    }
}
