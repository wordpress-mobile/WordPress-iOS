import WordPressFlux

struct ThemeSupportQuery {
    let blog: Blog
}

enum ThemeSupportStoreState {
    case empty
    case loading
    case loaded([[String: AnyHashable]]?)
    case error(Error)

    var shouldFetch: Bool {
        switch self {
        case .loaded:
            return false
        default:
            return true
        }
    }
}

class ThemeSupportStore: QueryStore<ThemeSupportStoreState, ThemeSupportQuery> {

    private struct JSONKeys {
        static let themeSupport = "theme_supports"
        static let colorPalette = "editor-color-palette"
    }

    private enum ErrorCode: Int {
        case processingError
    }

    init(dispatcher: ActionDispatcher = .global) {
        super.init(initialState: .empty, dispatcher: dispatcher)
    }

    override func queriesChanged() {
        guard !activeQueries.isEmpty && state.shouldFetch else {
            return
        }

        activeQueries.forEach { (query) in
            fetchTheme(for: query.blog)
        }
    }

    override func logError(_ error: String) {
        DDLogError("Error loading active theme: \(error)")
    }
}

private extension ThemeSupportStore {

    func fetchTheme(for blog: Blog) {
        state = .loading
        let requestPath = "/wp/v2/themes?status=active"
        GutenbergNetworkRequest(path: requestPath, blog: blog).request {  [weak self] result in
            switch result {
            case .success(let response):
                self?.processResponse(response)
            case .failure(let error):
                self?.state = .error(error)
            }
        }
    }

    func processResponse(_ response: Any) {
        let themeSupport = (response as? [[String: Any]])?.first?[JSONKeys.themeSupport]
        let colorPalette = (themeSupport as? [String: Any])?[JSONKeys.colorPalette] as? [[String: AnyHashable]]
        state = .loaded(colorPalette)
    }
}
