extension UIColor {

    static var invertedSystem5: UIColor {
        return UIColor(light: UIColor.systemGray5.color(for: UITraitCollection(userInterfaceStyle: .dark)),
                       dark: UIColor.systemGray5.color(for: UITraitCollection(userInterfaceStyle: .light)))
    }

    static var invertedLabel: UIColor {
        return UIColor(light: UIColor.label.color(for: UITraitCollection(userInterfaceStyle: .dark)),
                       dark: UIColor.label.color(for: UITraitCollection(userInterfaceStyle: .light)))
    }

    static var invertedSecondaryLabel: UIColor {
        return UIColor(light: UIColor.secondaryLabel.color(for: UITraitCollection(userInterfaceStyle: .dark)),
                       dark: UIColor.secondaryLabel.color(for: UITraitCollection(userInterfaceStyle: .light)))
    }

    static var invertedLink: UIColor {
        UIColor(light: .primary(.shade30), dark: .primary(.shade50))
    }

    static var invertedSeparator: UIColor {
        return UIColor(light: UIColor.separator.color(for: UITraitCollection(userInterfaceStyle: .dark)),
                       dark: UIColor.separator.color(for: UITraitCollection(userInterfaceStyle: .light)))
    }
}
