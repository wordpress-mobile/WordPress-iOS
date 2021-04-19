import Foundation
import Gutenberg

struct EditorTheme: Codable {
    static func == (lhs: EditorTheme, rhs: EditorTheme) -> Bool {
        return lhs.checksum == rhs.checksum
    }

    enum CodingKeys: String, CodingKey {
        case themeSupport = "theme_supports"
    }

    let themeSupport: EditorThemeSupport?
    let checksum: String

    init(from decoder: Decoder) throws {
        let map = try decoder.container(keyedBy: CodingKeys.self)
        let parsedTheme = try? map.decode(EditorThemeSupport.self, forKey: .themeSupport)
        self.themeSupport = parsedTheme
        self.checksum = {
            guard let parsedTheme = parsedTheme else { return "" }
            let encoder = JSONEncoder()
            encoder.outputFormatting = .sortedKeys
            let result: String
            do {
                let data = try encoder.encode(parsedTheme)
                result = String(data: data, encoding: .utf8) ?? ""
            } catch {
                result = ""
            }
            return result.md5()
        }()
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
