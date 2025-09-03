import Foundation

public class RemoteBlockEditorSettings: Codable {
    enum CodingKeys: String, CodingKey {
        case isFSETheme = "__unstableIsBlockBasedTheme"
        case galleryWithImageBlocks = "__unstableGalleryWithImageBlocks"
        case quoteBlockV2 = "__experimentalEnableQuoteBlockV2"
        case listBlockV2 = "__experimentalEnableListBlockV2"
        case rawStyles = "__experimentalStyles"
        case rawFeatures = "__experimentalFeatures"
        case colors
        case gradients
    }

    public let isFSETheme: Bool
    public let galleryWithImageBlocks: Bool
    public let quoteBlockV2: Bool
    public let listBlockV2: Bool
    public let rawStyles: String?
    public let rawFeatures: String?
    public let colors: [[String: String]]?
    public let gradients: [[String: String]]?

    public lazy var checksum: String = {
        return ChecksumUtil.checksum(from: self)
    }()

    private static func parseToString(_ container: KeyedDecodingContainer<CodingKeys>, _ key: CodingKeys) -> String? {
        // Swift cuurently doesn't support type conversions from Dictionaries to strings while decoding. So we need to
        // parse the reponse then convert it to a string.
        guard
            let json = try? container.decode([String: Any].self, forKey: key),
            let data = try? JSONSerialization.data(withJSONObject: json, options: [.sortedKeys])
        else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    required public init(from decoder: Decoder) throws {
        let map = try decoder.container(keyedBy: CodingKeys.self)
        self.isFSETheme = (try? map.decode(Bool.self, forKey: .isFSETheme)) ?? false
        self.galleryWithImageBlocks = (try? map.decode(Bool.self, forKey: .galleryWithImageBlocks)) ?? false
        self.quoteBlockV2 = (try? map.decode(Bool.self, forKey: .quoteBlockV2)) ?? false
        self.listBlockV2 = (try? map.decode(Bool.self, forKey: .listBlockV2)) ?? false
        self.rawStyles = RemoteBlockEditorSettings.parseToString(map, .rawStyles)
        self.rawFeatures = RemoteBlockEditorSettings.parseToString(map, .rawFeatures)
        self.colors = try? map.decode([[String: String]].self, forKey: .colors)
        self.gradients = try? map.decode([[String: String]].self, forKey: .gradients)
    }
}

// MARK: EditorTheme
public class RemoteEditorTheme: Codable {
    enum CodingKeys: String, CodingKey {
        case themeSupport = "theme_supports"
    }

    public let themeSupport: RemoteEditorThemeSupport?
    public lazy var checksum: String = {
        return ChecksumUtil.checksum(from: themeSupport)
    }()
}

public struct RemoteEditorThemeSupport: Codable {
    enum CodingKeys: String, CodingKey {
        case colors = "editor-color-palette"
        case gradients = "editor-gradient-presets"
        case blockTemplates = "block-templates"
    }

    public let colors: [[String: String]]?
    public let gradients: [[String: String]]?
    public let blockTemplates: Bool

    public init(from decoder: Decoder) throws {
        let map = try decoder.container(keyedBy: CodingKeys.self)
        self.colors = try? map.decode([[String: String]].self, forKey: .colors)
        self.gradients = try? map.decode([[String: String]].self, forKey: .gradients)
        self.blockTemplates = (try? map.decode(Bool.self, forKey: .blockTemplates)) ?? false
    }
}
