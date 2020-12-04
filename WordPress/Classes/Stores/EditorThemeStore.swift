import WordPressFlux

struct EditorThemeQuery {
    let blog: Blog
}

enum EditorThemeStoreState {
    typealias StoredThemes = [String: EditorTheme]
    case empty
    case loaded(StoredThemes)

    static func key(forBlog blog: Blog) -> String? {
        return blog.hostname as String?
    }

    func editorTheme(forBlog blog: Blog) -> EditorTheme? {
        guard let themeKey = EditorThemeStoreState.key(forBlog: blog) else {
            return nil
        }

        switch self {
        case .loaded(let themes):
            return themes[themeKey]
        default:
            return nil
        }
    }

    func storedThemes() -> StoredThemes {
        switch self {
        case .loaded(let themes):
            return themes
        default:
            return [:]
        }
    }
}

extension EditorThemeStoreState: Codable {

    enum Key: CodingKey {
        case rawValue
        case associatedValue
    }

    enum CodingError: Error {
        case unknownValue
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Key.self)
        let rawValue = try container.decode(Int.self, forKey: .rawValue)
        switch rawValue {
        case 0:
            self = .empty
        case 1:
            let themes = try container.decode(StoredThemes.self, forKey: .associatedValue)
            self = .loaded(themes)
        default:
            throw CodingError.unknownValue
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Key.self)
        switch self {
        case .empty:
            try container.encode(0, forKey: .rawValue)
        case .loaded(let themes):
            try container.encode(1, forKey: .rawValue)
            try container.encode(themes, forKey: .associatedValue)
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
        guard
            let responseData = try? JSONSerialization.data(withJSONObject: response, options: []),
            let themeKey = EditorThemeStoreState.key(forBlog: blog),
            let themeSupports = try? JSONDecoder().decode([EditorTheme].self, from: responseData),
            let newTheme = themeSupports.first
            else { return }

        var existingThemes = state.storedThemes()
        if newTheme != existingThemes[themeKey] {
            existingThemes[themeKey] = newTheme
            state = .loaded(existingThemes)
        }
    }
}
