import UIKit

extension WPStyleGuide {
    @objc class func configureFilterTabBar(_ filterTabBar: FilterTabBar) {
        filterTabBar.backgroundColor = .secondarySystemGroupedBackground
        filterTabBar.tintColor = .filterBarSelected
        filterTabBar.selectedTitleColor = .filterBarSelectedText
        filterTabBar.deselectedTabColor = .secondaryLabel
        filterTabBar.dividerColor = AppStyleGuide.neutral(.shade10)
    }
}
