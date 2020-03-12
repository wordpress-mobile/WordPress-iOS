import Foundation
import WordPressShared

extension WPStyleGuide {

    fileprivate static let barTintColor: UIColor = .neutral(.shade10)

    @objc public class func configureSearchBar(_ searchBar: UISearchBar) {
        searchBar.accessibilityIdentifier = "Search"
        searchBar.autocapitalizationType = .none
        searchBar.autocorrectionType = .no
        searchBar.isTranslucent = false
        searchBar.barTintColor = WPStyleGuide.barTintColor
        searchBar.layer.borderWidth = 1.0
        searchBar.returnKeyType = .done
        if #available(iOS 13.0, *) {
            searchBar.searchTextField.backgroundColor = .basicBackground
        }
    }

    @objc public class func configureSearchBarAppearance() {
        configureSearchBarTextAppearance()
        // Cancel button
        let barButtonItemAppearance = UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self])
        barButtonItemAppearance.tintColor = .neutral(.shade70)

        // We have to manually tint these images, as we want them
        // a different color from the search bar's cursor (which uses `tintColor`)
        let cancelImage = UIImage(named: "icon-clear-searchfield")?.imageWithTintColor(.neutral(.shade30))
        let searchImage = UIImage(named: "icon-post-list-search")?.imageWithTintColor(.neutral(.shade30))
        UISearchBar.appearance().setImage(cancelImage, for: .clear, state: UIControl.State())
        UISearchBar.appearance().setImage(searchImage, for: .search, state: UIControl.State())
    }

    @objc public class func configureSearchBarTextAppearance() {
        // Cancel button
        let barButtonTitleAttributes: [NSAttributedString.Key: Any] = [.font: WPStyleGuide.fixedFont(for: .headline),
                                                                      .foregroundColor: UIColor.neutral(.shade70)]
        let barButtonItemAppearance = UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self])
        barButtonItemAppearance.setTitleTextAttributes(barButtonTitleAttributes, for: UIControl.State())

        // Text field
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).defaultTextAttributes =
            (WPStyleGuide.defaultSearchBarTextAttributesSwifted(.neutral(.shade70)))
        let placeholderText = NSLocalizedString("Search", comment: "Placeholder text for the search bar")
        let attributedPlaceholderText = NSAttributedString(string: placeholderText,
                                                           attributes: WPStyleGuide.defaultSearchBarTextAttributesSwifted(.neutral(.shade30)))
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).attributedPlaceholder =
            attributedPlaceholderText
    }
}

extension UISearchBar {
    // Per Apple's documentation (https://developer.apple.com/documentation/xcode/supporting_dark_mode_in_your_interface),
    // `cgColor` objects do not adapt to appearance changes (i.e. toggling light/dark mode).
    // `tintColorDidChange` is called when the appearance changes, so re-set the border color when this occurs.
    open override func tintColorDidChange() {
        super.tintColorDidChange()
        layer.borderColor = WPStyleGuide.barTintColor.cgColor
    }
}
