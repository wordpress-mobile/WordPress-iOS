import Foundation
import WordPressShared

extension WPStyleGuide {

    public class func configureSearchBar(searchBar: UISearchBar) {
        searchBar.accessibilityIdentifier = NSLocalizedString("Search", comment: "")
        searchBar.autocapitalizationType = .None
        searchBar.autocorrectionType = .No
        searchBar.translucent = false
        searchBar.barTintColor = WPStyleGuide.greyLighten20()
        searchBar.layer.borderColor = WPStyleGuide.greyLighten20().CGColor
        searchBar.layer.borderWidth = 1.0
        searchBar.returnKeyType = .Done
    }

    public class func configureSearchAppearance() {
        // Cancel button
        let barButtonTitleAttributes = [ NSFontAttributeName: WPFontManager.systemRegularFontOfSize(17.0),
                           NSForegroundColorAttributeName: WPStyleGuide.darkGrey() ]

        let barButtonItemAppearance = UIBarButtonItem.appearanceWhenContainedInInstancesOfClasses([UISearchBar.self])
        barButtonItemAppearance.tintColor = WPStyleGuide.darkGrey()
        barButtonItemAppearance.setTitleTextAttributes(barButtonTitleAttributes, forState: .Normal)

        // Text field
        UITextField.appearanceWhenContainedInInstancesOfClasses([UISearchBar.self]).defaultTextAttributes = (WPStyleGuide.defaultSearchBarTextAttributes(WPStyleGuide.darkGrey()))
        let placeholderText = NSLocalizedString("Search", comment: "Placeholder text for the search bar")
        let attributedPlaceholderText = NSAttributedString(string: placeholderText, attributes: WPStyleGuide.defaultSearchBarTextAttributes(WPStyleGuide.grey()))
        UITextField.appearanceWhenContainedInInstancesOfClasses([UISearchBar.self]).attributedPlaceholder = attributedPlaceholderText

        // We have to manually tint these images, as we want them
        // a different color from the search bar's cursor (which uses `tintColor`)
        let cancelImage = UIImage(named: "icon-clear-searchfield")?.imageMaskedAndTintedWithColor(WPStyleGuide.grey())
        let searchImage = UIImage(named: "icon-post-list-search")?.imageMaskedAndTintedWithColor(WPStyleGuide.grey())
        UISearchBar.appearance().setImage(cancelImage, forSearchBarIcon:  .Clear, state: .Normal)
        UISearchBar.appearance().setImage(searchImage, forSearchBarIcon: .Search, state: .Normal)

    }
}
