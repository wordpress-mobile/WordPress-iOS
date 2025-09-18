import Foundation
import WordPressShared
import UIKit

extension WPStyleGuide {

    public class func configureSearchBar(_ searchBar: UISearchBar, backgroundColor: UIColor, returnKeyType: UIReturnKeyType) {
        searchBar.accessibilityIdentifier = "Search"
        searchBar.autocapitalizationType = .none
        searchBar.autocorrectionType = .no
        if #available(iOS 26, *) {
            searchBar.searchBarStyle = .minimal // Removes borders
        } else {
            searchBar.isTranslucent = true
            searchBar.backgroundImage = UIImage()
            searchBar.backgroundColor = backgroundColor
        }
        searchBar.returnKeyType = returnKeyType
    }

    /// configures a search bar with a default `.appBackground` color and a `.done` return key
    @objc public class func configureSearchBar(_ searchBar: UISearchBar) {
        configureSearchBar(searchBar, backgroundColor: .secondarySystemGroupedBackground, returnKeyType: .done)
    }
}
