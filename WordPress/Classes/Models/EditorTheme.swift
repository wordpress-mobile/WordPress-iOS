import Foundation
import Gutenberg

struct EditorTheme: Codable, Equatable {
    static func == (lhs: EditorTheme, rhs: EditorTheme) -> Bool {
        return lhs.description == rhs.description
    }

    enum CodingKeys: String, CodingKey {
        case themeSupport = "theme_supports"
        case version
        case stylesheet
    }

    let themeSupport: EditorThemeSupport?
    let version: String?
    let stylesheet: String?

    var description: String {
        return "\(stylesheet ?? "")-\(version ?? "")"
    }

    init(from decoder: Decoder) throws {
        let map = try decoder.container(keyedBy: CodingKeys.self)
        self.themeSupport = try? map.decode(EditorThemeSupport.self, forKey: .themeSupport)
        self.version = try? map.decode(String.self, forKey: .version)
        self.stylesheet = try? map.decode(String.self, forKey: .stylesheet)
    }
}

struct EditorThemeSupport: Codable, GutenbergEditorTheme {

    enum CodingKeys: String, CodingKey {
        case colors = "editor-color-palette"
        case gradients = "editor-gradient-presets"
    }

    let colors: [[String: String]]?
    let gradients: [[String: String]]?

    init(from decoder: Decoder) throws {
        let map = try decoder.container(keyedBy: CodingKeys.self)
        self.colors = try? map.decode([[String: String]].self, forKey: .colors)
        self.gradients = try? map.decode([[String: String]].self, forKey: .gradients)
    }
}
