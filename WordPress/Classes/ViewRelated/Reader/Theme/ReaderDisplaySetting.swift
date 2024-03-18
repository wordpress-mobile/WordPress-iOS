import WordPressUI

struct ReaderDisplaySetting: Codable {

    // MARK: Properties

    // The default display setting.
    static let `default` = ReaderDisplaySetting(color: .sepia, font: .sans, size: .normal)

    let color: Color
    let font: Font
    let size: Size

    // MARK: Methods

    func toDictionary(_ encoder: JSONEncoder = JSONEncoder()) throws -> NSDictionary? {
        let data = try encoder.encode(self)
        return try JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary
    }

    // MARK: Types

    enum Color: String, Codable, CaseIterable {
        case system
        case paper
        case sepia
        case charcoal
        case oled

        // TODO: Consider localization
        var label: String {
            switch self {
            case .system:
                return "Default"
            case .paper:
                return "Paper"
            case .sepia:
                return "Sepia"
            case .charcoal:
                return "Charcoal"
            case .oled:
                return "OLED"
            }
        }

        var foreground: UIColor {
            switch self {
            case .system:
                return .text
            case .paper:
                return .init(fromHex: 0x2d2e2e)
            case .sepia:
                return .init(fromHex: 0x27201b)
            case .charcoal:
                return .init(fromHex: 0xabaab2)
            case .oled:
                return .text.color(for: .init(userInterfaceStyle: .dark))
            }
        }

        var secondaryForeground: UIColor {
            switch self {
            case .system:
                return .secondaryLabel
            default:
                return foreground.withAlphaComponent(0.6)
            }
        }

        var background: UIColor {
            switch self {
            case .system:
                return .systemBackground
            case .paper:
                return .init(fromHex: 0xf2f2f2)
            case .sepia:
                return .init(fromHex: 0xeae0cd)
            case .charcoal:
                return .init(fromHex: 0x3a3a3c)
            case .oled:
                return .systemBackground.color(for: .init(userInterfaceStyle: .dark))
            }
        }

        /// Whether the color adjusts between light and dark mode.
        var adaptsToInterfaceStyle: Bool {
            switch self {
            case .system:
                return true
            default:
                return false
            }
        }
    }

    // TODO: Need to import the fonts
    enum Font: String, Codable, CaseIterable {
        case sans
        case serif
        case mono
        case olde
        case rock
    }

    // TODO: Determine the magnitude
    enum Size: String, Codable, CaseIterable {
        case smaller
        case smallest
        case normal
        case large
        case larger
    }

    // MARK: Codable

    private enum CodingKeys: String, CodingKey {
        case color
        case font
        case size
    }
}

// MARK: - Controller

/// This should be the object to be strongly retained. Keeps the store up-to-date.
class ReaderDisplaySettingStore: NSObject {

    private let repository: UserPersistentRepository

    var setting: ReaderDisplaySetting = .default {
        didSet {
            if let dictionary = try? setting.toDictionary() {
                repository.set(dictionary, forKey: Constants.key)
            }
        }
    }

    init(repository: UserPersistentRepository = UserPersistentStoreFactory.instance()) {
        self.repository = repository
        self.setting = {
            guard let dictionary = repository.dictionary(forKey: Constants.key),
                  let data = try? JSONSerialization.data(withJSONObject: dictionary),
                  let setting = try? JSONDecoder().decode(ReaderDisplaySetting.self, from: data) else {
                return .default
            }
            return setting
        }()
        super.init()
    }

    private struct Constants {
        static let key = "readerDisplaySettingKey"
    }
}
