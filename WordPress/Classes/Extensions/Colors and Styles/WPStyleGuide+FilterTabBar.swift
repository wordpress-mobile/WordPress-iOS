import UIKit

extension WPStyleGuide {
    @objc class func configureFilterTabBar(_ filterTabBar: FilterTabBar) {
        filterTabBar.backgroundColor = .filterBarBackground
        filterTabBar.tintColor = .filterBarSelected
        filterTabBar.deselectedTabColor = .textSubtle
        filterTabBar.dividerColor = .neutral(.shade10)
    }
}
