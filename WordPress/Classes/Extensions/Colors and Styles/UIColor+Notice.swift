extension UIColor {

    static var invertedSystem5: UIColor {
        if #available(iOS 13.0, *) {
            return UIColor(light: UIColor.systemGray5.color(for: UITraitCollection(userInterfaceStyle: .dark)),
                           dark: UIColor.systemGray5.color(for: UITraitCollection(userInterfaceStyle: .light)))
        } else {
            return UIColor(displayP3Red: 44/255, green: 44/255, blue: 46/266, alpha: 1)
        }
    }

    static var invertedLabel: UIColor {
        if #available(iOS 13.0, *) {
            return UIColor(light: UIColor.label.color(for: UITraitCollection(userInterfaceStyle: .dark)),
                           dark: UIColor.label.color(for: UITraitCollection(userInterfaceStyle: .light)))
        } else {
            return .white
        }
    }

    static var invertedSecondaryLabel: UIColor {
        if #available(iOS 13.0, *) {
            return UIColor(light: UIColor.secondaryLabel.color(for: UITraitCollection(userInterfaceStyle: .dark)),
                           dark: UIColor.secondaryLabel.color(for: UITraitCollection(userInterfaceStyle: .light)))
        } else {
            return UIColor(displayP3Red: 235/255, green: 235/255, blue: 245/255, alpha: 0.6)
        }
    }

    static var invertedLink: UIColor {
        UIColor(light: .primary(.shade30), dark: .primary(.shade50))
    }

    static var invertedSeparator: UIColor {
        if #available(iOS 13.0, *) {
            return UIColor(light: UIColor.separator.color(for: UITraitCollection(userInterfaceStyle: .dark)),
                           dark: UIColor.separator.color(for: UITraitCollection(userInterfaceStyle: .light)))
        } else {
            return UIColor(displayP3Red: 84/255, green: 84/255, blue: 88/255, alpha: 0.6)
        }
    }
}
