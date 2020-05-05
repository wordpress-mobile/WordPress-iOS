import WordPressFlux

struct EditorThemeQuery {
    let blog: Blog
}

enum EditorThemeStoreState {
    typealias StoredThemeColors = [String: [[String: AnyHashable]]]
    case empty
    case loaded(StoredThemeColors)

    static func key(forBlog blog: Blog) -> String? {
        guard let blogID = blog.dotComID else {
            return nil
        }

        return "\(blogID)"
    }

    func themeColors(forBlog blog: Blog) -> [[String: AnyHashable]]? {

        guard let themeKey = EditorThemeStoreState.key(forBlog: blog) else {
            return nil
        }

        switch self {
        case .loaded(let colors):
            return colors[themeKey]
        default:
            return nil
        }
    }

    func storedthemeColors() -> StoredThemeColors {
        switch self {
        case .loaded(let colors):
            return colors
        default:
            return [:]
        }
    }
}

class EditorThemeStore: QueryStore<EditorThemeStoreState, EditorThemeQuery> {

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

        activeQueries.forEach { (query) in
            if state.themeColors(forBlog: query.blog) == nil {
                fetchTheme(for: query.blog)
            }
        }
    }

    override func logError(_ error: String) {
        DDLogError("Error loading active theme: \(error)")
    }
}

private extension EditorThemeStore {

    func fetchTheme(for blog: Blog) {
        let requestPath = "/wp/v2/themes?status=active"
        GutenbergNetworkRequest(path: requestPath, blog: blog).request {  [weak self] result in
            switch result {
            case .success(let response):
                self?.processResponse(response, for: blog)
            case .failure(let error):
                DDLogError("Error loading active theme: \(error)")
            }
        }
    }

    func processResponse(_ response: Any, for blog: Blog) {
        let themeSupport = (response as? [[String: Any]])?.first?[JSONKeys.themeSupport]
        let colorPalette = (themeSupport as? [String: Any])?[JSONKeys.colorPalette] as? [[String: AnyHashable]]

        if let themeKey = EditorThemeStoreState.key(forBlog: blog) {
            var existingThemes = state.storedthemeColors()
            existingThemes[themeKey] = colorPalette ?? [] // Check for if things have changed or not
            state = .loaded(existingThemes)
        }
    }
}
