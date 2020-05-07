import WordPressFlux

struct EditorThemeQuery {
    let blog: Blog
}

enum EditorThemeStoreState {
    typealias StoredThemeColors = [String: EditorTheme]
    case empty
    case loaded(StoredThemeColors)

    static func key(forBlog blog: Blog) -> String? {
        return blog.hostname as String?
    }

    func editorTheme(forBlog blog: Blog) -> EditorTheme? {

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

    private enum ErrorCode: Int {
        case processingError
    }

    init(dispatcher: ActionDispatcher = .global) {
        super.init(initialState: .empty, dispatcher: dispatcher)
    }

    override func queriesChanged() {

        activeQueries.forEach { (query) in
            fetchTheme(for: query.blog)
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
        guard let responseData = try? JSONSerialization.data(withJSONObject: response, options: []) else { return }
        let themeSupports = try? JSONDecoder().decode([EditorTheme].self, from: responseData)

        if let themeKey = EditorThemeStoreState.key(forBlog: blog),
            let newTheme = themeSupports?.first {
            var existingThemes = state.storedthemeColors()

            if newTheme != existingThemes[themeKey] {
                existingThemes[themeKey] = newTheme
                state = .loaded(existingThemes)
            }
        }
    }
}
