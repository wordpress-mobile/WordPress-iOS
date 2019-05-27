/// Generates the names of the named colors in the ColorPalette.xcasset
enum WPComColorName: String {
    // MARK: - Base colors
    case Blue
    case Celadon
    case Gray
    case Green
    case HotBlue = "Hot-Blue"
    case HotGreen = "Hot-Green"
    case HotOrange = "Hot-Orange"
    case HotPink = "Hot-Pink"
    case HotPurple = "Hot-Purple"
    case HotRed = "Hot-Red"
    case HotYellow = "Hot-Yellow"
    case JetpackGreen = "Jetpack-Green"
    case Orange
    case Pink
    case Purple
    case Red
    case WooPurple = "Woo-Purple"
    case Yellow

    // MARK: - Semantic colors
    static let Accent = WPComColorName.HotPink
    static let Divider = WPComColorName.Gray.shade50
    static let Error = WPComColorName.HotRed
    static let Neutral = WPComColorName.Gray
    static let Primary = WPComColorName.Blue
    static let Success = WPComColorName.Green
    static let Text = WPComColorName.Gray.shade800
    static let TextSubtle = WPComColorName.Gray.shade500
    static let Warning = WPComColorName.HotYellow

    // MARK: - color shades
    var shade0: String {
        return shade(0)
    }
    var shade50: String {
        return shade(50)
    }
    var shade100: String {
        return shade(100)
    }
    var shade200: String {
        return shade(200)
    }
    var shade300: String {
        return shade(300)
    }
    var shade400: String {
        return shade(400)
    }
    var shade500: String {
        return shade(500)
    }
    var shade600: String {
        return shade(600)
    }
    var shade700: String {
        return shade(700)
    }
    var shade800: String {
        return shade(800)
    }
    var shade900: String {
        return shade(900)
    }
    var baseColor: String {
        return self.shade500
    }

    func shade(_ units: Int = 500) -> String {
        let acceptableValues = [0, 50, 100, 200, 300, 400, 500, 600, 700, 800, 900]
        let shade = acceptableValues.first { $0 >= units } ?? acceptableValues.last!
        return "\(self)-\(shade)"
    }
}

extension UIColor {
    func wpcom(color: WPComColorName, shade: Int = 500) -> UIColor {
        return UIColor(named: color.shade(shade)) ?? .red
    }

    var accent: UIColor {
        return wpcom(color: .Accent)
    }

    // should shade be strongly typed? with only 11 possible values, I think so
    func accent(shade: Int) -> UIColor {
        return wpcom(color: .Accent, shade: shade)
    }
}
