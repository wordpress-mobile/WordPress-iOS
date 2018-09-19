import Foundation
import WordPressShared

extension WPStyleGuide {

    @objc public class func configureSearchBar(_ searchBar: UISearchBar) {
        searchBar.accessibilityIdentifier = "Search"
        searchBar.autocapitalizationType = .none
        searchBar.autocorrectionType = .no
        searchBar.isTranslucent = false
        searchBar.barTintColor = WPStyleGuide.greyLighten20()
        searchBar.layer.borderColor = WPStyleGuide.greyLighten20().cgColor
        searchBar.layer.borderWidth = 1.0
        searchBar.returnKeyType = .done
    }

    @objc public class func configureSearchBarAppearance() {
        configureSearchBarTextAppearance()
        // Cancel button
        let barButtonItemAppearance = UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self])
        barButtonItemAppearance.tintColor = WPStyleGuide.darkGrey()

        // We have to manually tint these images, as we want them
        // a different color from the search bar's cursor (which uses `tintColor`)
        let cancelImage = UIImage(named: "icon-clear-searchfield")?.imageWithTintColor(WPStyleGuide.grey())
        let searchImage = UIImage(named: "icon-post-list-search")?.imageWithTintColor(WPStyleGuide.grey())
        UISearchBar.appearance().setImage(cancelImage, for: .clear, state: UIControl.State())
        UISearchBar.appearance().setImage(searchImage, for: .search, state: UIControl.State())
    }

    @objc public class func configureSearchBarTextAppearance() {
        // Cancel button
        let barButtonTitleAttributes: [NSAttributedString.Key: Any] = [.font: WPStyleGuide.fixedFont(for: .headline),
                                                                      .foregroundColor: WPStyleGuide.darkGrey()]
        let barButtonItemAppearance = UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self])
        barButtonItemAppearance.setTitleTextAttributes(barButtonTitleAttributes, for: UIControl.State())

        // Text field
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).defaultTextAttributes =
            (WPStyleGuide.defaultSearchBarTextAttributesSwifted(WPStyleGuide.darkGrey()))
        let placeholderText = NSLocalizedString("Search", comment: "Placeholder text for the search bar")
        let attributedPlaceholderText = NSAttributedString(string: placeholderText,
                                                           attributes: WPStyleGuide.defaultSearchBarTextAttributesSwifted(WPStyleGuide.grey()))
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).attributedPlaceholder =
            attributedPlaceholderText
    }
}
