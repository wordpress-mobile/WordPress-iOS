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

    let themeSupport: EditorThemeSupport
    let version: String?
    let stylesheet: String?

    var description: String {
        return "\(stylesheet ?? "")-\(version ?? "")"
    }
}

struct EditorThemeSupport: Codable, GutenbergEditorTheme {

    enum CodingKeys: String, CodingKey {
        case colors = "editor-color-palette"
        case gradients = "editor-gradient-presets"
    }

    let colors: [[String: String]]?
    let gradients: [[String: String]]?
}
