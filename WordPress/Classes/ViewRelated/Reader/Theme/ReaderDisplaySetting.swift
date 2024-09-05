import WordPressUI
import WordPressShared

struct ReaderDisplaySetting: Codable, Equatable {

    static var customizationEnabled: Bool {
        AppConfiguration.isJetpack && RemoteFeatureFlag.readingPreferences.enabled()
    }

    // MARK: Properties

    // The default display setting.
    static let standard = ReaderDisplaySetting(color: .system, font: .sans, size: .normal)

    var color: Color
    var font: Font
    var size: Size

    var hasLightBackground: Bool {
        color.background.brighterThan(0.5)
    }

    var isDefaultSetting: Bool {
        return self == .standard
    }

    // MARK: Methods

    /// Generates a `UIFont` with customizable parameters.
    ///
    /// - Parameters:
    ///   - font: The `ReaderDisplaySetting.Font` type.
    ///   - size: The `ReaderDisplaySetting.Size`. Defaults to `.normal`.
    ///   - textStyle: The preferred text style.
    ///   - weight: The preferred weight. Defaults to nil, which falls back to the inherent weight from the `UITextStyle`.
    /// - Returns: A `UIFont` instance with the specified configuration.
    static func font(with font: Font,
                     size: Size = .normal,
                     textStyle: UIFont.TextStyle,
                     weight: UIFont.Weight? = nil) -> UIFont {
        let descriptor: UIFontDescriptor = {
            let defaultDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: textStyle)

            /// If weight is not specified, do not override any attributes.
            /// Some default styles have preferred weight (e.g., `headline`), so we should preserve it.
            guard let weight else {
                return defaultDescriptor
            }

            var traits = (defaultDescriptor.fontAttributes[.traits] as? [UIFontDescriptor.TraitKey: Any]) ?? [:]
            traits[UIFontDescriptor.TraitKey.weight] = weight

            return defaultDescriptor.addingAttributes([.traits: traits])
        }()

        let pointSize = descriptor.pointSize * size.scale

        switch font {
        case .serif:
            return WPStyleGuide.serifFontForTextStyle(textStyle, fontWeight: weight ?? .regular).withSize(pointSize)
        case .mono:
            let descriptorWithDesign = descriptor.withDesign(.monospaced) ?? descriptor
            return UIFont(descriptor: descriptorWithDesign, size: descriptorWithDesign.pointSize * size.scale)
        default:
            return UIFont(descriptor: descriptor, size: pointSize)
        }
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
        case hacker
        case candy

        var label: String {
            switch self {
            case .system:
                return NSLocalizedString(
                    "reader.preferences.color.default",
                    value: "Default",
                    comment: "Name for the Default color theme, used in the Reader's reading preferences."
                )
            case .soft:
                return NSLocalizedString(
                    "reader.preferences.color.soft",
                    value: "Soft",
                    comment: "Name for the Soft color theme, used in the Reader's reading preferences."
                )
            case .sepia:
                return NSLocalizedString(
                    "reader.preferences.color.sepia",
                    value: "Sepia",
                    comment: "Name for the Sepia color theme, used in the Reader's reading preferences."
                )
            case .evening:
                return NSLocalizedString(
                    "reader.preferences.color.evening",
                    value: "Evening",
                    comment: "Name for the Evening color theme, used in the Reader's reading preferences."
                )
            case .oled:
                return NSLocalizedString(
                    "reader.preferences.color.oled",
                    value: "OLED",
                    comment: "Name for the OLED color theme, used in the Reader's reading preferences."
                )
            case .hacker:
                return NSLocalizedString(
                    "reader.preferences.color.h4x0r",
                    value: "h4x0r",
                    comment: "Name for the h4x0r color theme, used in the Reader's reading preferences."
                )
            case .candy:
                return NSLocalizedString(
                    "reader.preferences.color.candy",
                    value: "Candy",
                    comment: "Name for the Candy color theme, used in the Reader's reading preferences."
                )
            }
        }

        var foreground: UIColor {
            switch self {
            case .system:
                return .label
            case .soft:
                return UIColor(fromHex: 0x2d2e2e)
            case .sepia:
                return UIColor(fromHex: 0x27201b)
            case .evening:
                return UIColor(fromHex: 0xabaab2)
            case .oled:
                return .label.color(for: .init(userInterfaceStyle: .dark))
            case .hacker:
                return .green
            case .candy:
                return UIColor(fromHex: 0x0066ff)
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
                return UIColor(fromHex: 0xf2f2f2)
            case .sepia:
                return UIColor(fromHex: 0xeae0cd)
            case .evening:
                return UIColor(fromHex: 0x3a3a3c)
            case .oled:
                return .systemBackground.color(for: .init(userInterfaceStyle: .dark))
            case .hacker:
                return .systemBackground.color(for: .init(userInterfaceStyle: .dark))
            case .candy:
                return UIColor(fromHex: 0xffe8fd)
            }
        }

        var secondaryBackground: UIColor {
            switch self {
            case .system:
                return .secondarySystemBackground
            case .evening, .oled, .hacker:
                return foreground.withAlphaComponent(0.15) // slightly higher contrast for dark themes.
            default:
                return foreground.withAlphaComponent(0.1)
            }
        }

        var border: UIColor {
            switch self {
            case .system:
                return .separator
            default:
                return foreground.withAlphaComponent(0.3)
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

        var valueForTracks: String {
            switch self {
            case .system:
                return "default"
            case .hacker:
                return "h4x0r"
            default:
                return rawValue
            }
        }
    }

    enum Font: String, Codable, CaseIterable {
        case sans
        case serif
        case mono

        var cssString: String {
            switch self {
            case .sans:
                return "-apple-system, sans-serif"
            case .serif:
                return "'Noto Serif', serif"
            case .mono:
                return "'SF Mono', SFMono-Regular, ui-monospace, monospace"
            }
        }

        var valueForTracks: String {
            rawValue
        }
    }

    enum Size: Int, Codable, CaseIterable {
        case extraSmall = -2
        case small
        case normal
        case large
        case extraLarge

        var scale: Double {
            switch self {
            case .extraSmall:
                return 0.75
            case .small:
                return 0.9
            case .normal:
                return 1.0
            case .large:
                return 1.15
            case .extraLarge:
                return 1.25
            }
        }

        var accessibilityLabel: String {
            switch self {
            case .extraSmall:
                return NSLocalizedString(
                    "reader.preferences.size.extraSmall",
                    value: "Extra Small",
                    comment: "Accessibility label for the Extra Small size option, used in the Reader's reading preferences."
                )
            case .small:
                return NSLocalizedString(
                    "reader.preferences.size.small",
                    value: "Small",
                    comment: "Accessibility label for the Small size option, used in the Reader's reading preferences."
                )
            case .normal:
                return NSLocalizedString(
                    "reader.preferences.size.normal",
                    value: "Normal",
                    comment: "Accessibility label for the Normal size option, used in the Reader's reading preferences."
                )
            case .large:
                return NSLocalizedString(
                    "reader.preferences.size.large",
                    value: "Large",
                    comment: "Accessibility label for the Large size option, used in the Reader's reading preferences."
                )
            case .extraLarge:
                return NSLocalizedString(
                    "reader.preferences.size.extraLarge",
                    value: "Extra Large",
                    comment: "Accessibility label for the Extra Large size option, used in the Reader's reading preferences."
                )
            }
        }

        var valueForTracks: String {
            switch self {
            case .extraSmall:
                return "extra_small"
            case .small:
                return "small"
            case .normal:
                return "normal"
            case .large:
                return "large"
            case .extraLarge:
                return "extra_large"
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

protocol ReaderDisplaySettingStoreDelegate: NSObjectProtocol {
    func displaySettingDidChange()
}

/// This should be the object to be strongly retained. Keeps the store up-to-date.
class ReaderDisplaySettingStore: NSObject {

    private let repository: UserPersistentRepository

    private let notificationCenter: NotificationCenter

    weak var delegate: ReaderDisplaySettingStoreDelegate?

    /// A public facade to simplify the flag checking dance for the `ReaderDisplaySetting` object.
    /// When the flag is disabled, this will always return the `standard` object, and the setter does nothing.
    var setting: ReaderDisplaySetting {
        get {
            return ReaderDisplaySetting.customizationEnabled ? _setting : .standard
        }
        set {
            guard ReaderDisplaySetting.customizationEnabled,
                  newValue != _setting else {
                return
            }
            _setting = newValue
            broadcastChangeNotification()
        }
    }

    /// The actual instance variable that holds the setting object.
    /// This is intentionally set to private so that it's only controllable by `ReaderDisplaySettingStore`.
    private var _setting: ReaderDisplaySetting = .standard {
        didSet {
            guard oldValue != _setting,
                  let dictionary = try? setting.toDictionary() else {
                return
            }
            repository.set(dictionary, forKey: Constants.key)
        }
    }

    init(repository: UserPersistentRepository = UserPersistentStoreFactory.instance(),
         notificationCenter: NotificationCenter = .default) {
        self.repository = repository
        self.notificationCenter = notificationCenter
        self._setting = {
            guard let dictionary = repository.dictionary(forKey: Constants.key),
                  let data = try? JSONSerialization.data(withJSONObject: dictionary),
                  let setting = try? JSONDecoder().decode(ReaderDisplaySetting.self, from: data) else {
                return .standard
            }
            return setting
        }()
        super.init()
        registerNotifications()
    }

    private func registerNotifications() {
        notificationCenter.addObserver(self,
                                       selector: #selector(handleChangeNotification),
                                       name: .readerDisplaySettingStoreDidChange,
                                       object: nil)
    }

    private func broadcastChangeNotification() {
        notificationCenter.post(name: .readerDisplaySettingStoreDidChange, object: self)
    }

    @objc
    private func handleChangeNotification(_ notification: NSNotification) {
        // ignore self broadcasts.
        if let broadcaster = notification.object as? ReaderDisplaySettingStore,
           broadcaster == self {
            return
        }

        // since we're handling change notifications, a stored setting object *should* exist.
        guard let updatedSetting = try? fetchSetting() else {
            DDLogError("ReaderDisplaySettingStore: Received a didChange notification with a nil stored value")
            return
        }

        _setting = updatedSetting
        delegate?.displaySettingDidChange()
    }

    /// Fetches the stored value of `ReaderDisplaySetting`.
    ///
    /// - Returns: `ReaderDisplaySetting`
    private func fetchSetting() throws -> ReaderDisplaySetting? {
        guard let dictionary = repository.dictionary(forKey: Constants.key) else {
            return nil
        }

        let data = try JSONSerialization.data(withJSONObject: dictionary)
        let setting = try JSONDecoder().decode(ReaderDisplaySetting.self, from: data)
        return setting
    }

    private struct Constants {
        static let key = "readerDisplaySettingKey"
    }
}

fileprivate extension NSNotification.Name {
    static let readerDisplaySettingStoreDidChange = NSNotification.Name("ReaderDisplaySettingDidChange")
}

private extension UIColor {
    /**
    Whether or not the color brightness is higher than a provided brightness value.

    - parameter brightnessValue: A number that represents the brightness of a color. It ranges from 0.0 (black) to 1.0 (white).
    - return: YES if brightness is higher than the brightness value provided.
    */
    func brighterThan(_ brightnessValue: Double) -> Bool {
        return Double(YIQBrightness()) / 255 > brightnessValue
    }

    /// http://en.wikipedia.org/wiki/YIQ
    private func YIQBrightness() -> Int {
        let componentInts = calculateRGBComponentIntegers()
        let red = componentInts.red * 299
        let green = componentInts.green * 587
        let blue = componentInts.blue * 114
        let brightness = (red + green + blue) / 1000

        return brightness
    }

    /// Calculates the RGB color components of a color as an Integer value, even if it is the grayscale space. Values between 0.0 - 255.0 are in the sRGB gamut range.
    private func calculateRGBComponentIntegers()  -> (red: Int, green: Int, blue: Int, alpha: Int) {
        let components = calculateRGBComponents()
        return (Int(components.red * 255.0), Int(components.green * 255.0), Int(components.blue * 255.0), Int(components.alpha))
    }

    /// Calculates the RGB color components of a color as a CGFloat value, even if it is the grayscale space. Values for red, green, and blue can be of any range due to API changes. Values between 0.0 - 1.0 are in the sRGB gamut range.
    private func calculateRGBComponents() -> (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        var w: CGFloat = 0
        let convertedToRGBSpace = self.getRed(&r, green: &g, blue: &b, alpha: &a)
        if !convertedToRGBSpace {
            getWhite(&w, alpha: &a)
            r = w
            g = w
            b = w
        }
        return (r, g, b, a)
    }
}
