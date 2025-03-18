import UIKit
import WordPressUI

extension WPStyleGuide {
    @objc class func configureFilterTabBar(_ filterTabBar: FilterTabBar) {
        filterTabBar.backgroundColor = .secondarySystemGroupedBackground
        filterTabBar.tintColor = .label
        filterTabBar.selectedTitleColor = .label
        filterTabBar.deselectedTabColor = .secondaryLabel
        filterTabBar.dividerColor = UIAppColor.neutral(.shade10)
    }
}
