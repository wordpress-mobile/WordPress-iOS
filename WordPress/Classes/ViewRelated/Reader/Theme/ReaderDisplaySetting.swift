import WordPressUI
import WordPressShared

struct ReaderDisplaySetting: Codable, Equatable {

    // MARK: Properties

    // The default display setting.
    static let `default` = ReaderDisplaySetting(color: .system, font: .sans, size: .normal)

    var color: Color
    var font: Font
    var size: Size

    // MARK: Methods

    static func font(with font: Font,
                     size: Size = .normal,
                     textStyle: UIFont.TextStyle,
                     weight: UIFont.Weight = .regular) -> UIFont {
        let scale = size.scale
        let metrics = UIFontMetrics(forTextStyle: textStyle)
        let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: textStyle)
        let pointSize = descriptor.pointSize * scale

        let uiFont = {
            switch font {
            case .serif:
                return WPStyleGuide.serifFontForTextStyle(textStyle).withSize(pointSize)
            case .mono:
                return .monospacedSystemFont(ofSize: pointSize, weight: .regular)
            default:
                return .systemFont(ofSize: pointSize)
            }
        }()

        return metrics.scaledFont(for: uiFont)
    }

    func font(with textStyle: UIFont.TextStyle, weight: UIFont.Weight = .regular) -> UIFont {
        return Self.font(with: font, size: size, textStyle: textStyle, weight: weight)
    }

    func toDictionary(_ encoder: JSONEncoder = JSONEncoder()) throws -> NSDictionary? {
        let data = try encoder.encode(self)
        return try JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary
    }

    // MARK: Types

    enum Color: String, Codable, CaseIterable {
        case system
        case soft
        case sepia
        case evening
        case oled

        // TODO: Consider localization
        var label: String {
            switch self {
            case .system:
                return "Default"
            case .soft:
                return "Soft"
            case .sepia:
                return "Sepia"
            case .evening:
                return "Evening"
            case .oled:
                return "OLED"
            }
        }

        var foreground: UIColor {
            switch self {
            case .system:
                return .text
            case .soft:
                return .init(fromHex: 0x2d2e2e)
            case .sepia:
                return .init(fromHex: 0x27201b)
            case .evening:
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
            case .soft:
                return .init(fromHex: 0xf2f2f2)
            case .sepia:
                return .init(fromHex: 0xeae0cd)
            case .evening:
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
//        case olde
//        case rock
    }

    // TODO: Determine the magnitude
    enum Size: Int, Codable, CaseIterable {
        case smaller = -2
        case small
        case normal
        case large
        case larger

        var scale: Double {
            switch self {
            case .smaller:
                return 0.75
            case .small:
                return 0.9
            case .normal:
                return 1.0
            case .large:
                return 1.15
            case .larger:
                return 1.25
            }
        }
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

    var setting: ReaderDisplaySetting {
        get {
            return FeatureFlag.readerCustomization.enabled ? _setting : .default
        }
        set {
            guard FeatureFlag.readerCustomization.enabled else {
                return
            }
            _setting = newValue
        }
    }

    private var _setting: ReaderDisplaySetting = .default {
        didSet {
            if let dictionary = try? setting.toDictionary() {
                repository.set(dictionary, forKey: Constants.key)
            }
        }
    }

    init(repository: UserPersistentRepository = UserPersistentStoreFactory.instance()) {
        self.repository = repository
        self._setting = {
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
