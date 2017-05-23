import Foundation
import WordPressShared

extension WPStyleGuide {

    public class func configureSearchBar(_ searchBar: UISearchBar) {
        searchBar.accessibilityIdentifier = NSLocalizedString("Search", comment: "")
        searchBar.autocapitalizationType = .none
        searchBar.autocorrectionType = .no
        searchBar.isTranslucent = false
        searchBar.barTintColor = WPStyleGuide.greyLighten20()
        searchBar.layer.borderColor = WPStyleGuide.greyLighten20().cgColor
        searchBar.layer.borderWidth = 1.0
        searchBar.returnKeyType = .done
    }

    public class func configureSearchAppearance() {
        // Cancel button
        let barButtonTitleAttributes: [String: Any] = [NSFontAttributeName: WPStyleGuide.fontForTextStyle(.headline),
                           NSForegroundColorAttributeName: WPStyleGuide.darkGrey()]

        let barButtonItemAppearance = UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self])
        barButtonItemAppearance.tintColor = WPStyleGuide.darkGrey()
        barButtonItemAppearance.setTitleTextAttributes(barButtonTitleAttributes, for: UIControlState())

        // Text field
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).defaultTextAttributes = (WPStyleGuide.defaultSearchBarTextAttributes(WPStyleGuide.darkGrey()))
        let placeholderText = NSLocalizedString("Search", comment: "Placeholder text for the search bar")
        let attributedPlaceholderText = NSAttributedString(string: placeholderText, attributes: WPStyleGuide.defaultSearchBarTextAttributes(WPStyleGuide.grey()))
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).attributedPlaceholder = attributedPlaceholderText

        // We have to manually tint these images, as we want them
        // a different color from the search bar's cursor (which uses `tintColor`)
        let cancelImage = UIImage(named: "icon-clear-searchfield")?.imageWithTintColor(WPStyleGuide.grey())
        let searchImage = UIImage(named: "icon-post-list-search")?.imageWithTintColor(WPStyleGuide.grey())
        UISearchBar.appearance().setImage(cancelImage, for:  .clear, state: UIControlState())
        UISearchBar.appearance().setImage(searchImage, for: .search, state: UIControlState())

    }
}
