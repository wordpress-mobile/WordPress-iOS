extension CommentsViewController {

    enum CommentFilter: Int, FilterTabBarItem, CaseIterable {
        case all
        case pending
        case approved
        case trashed
        case spam

        var title: String {
            switch self {
            case .all: return NSLocalizedString("All", comment: "Title of all Comments filter.")
            case .pending: return NSLocalizedString("Pending", comment: "Title of pending Comments filter.")
            case .approved: return NSLocalizedString("Approved", comment: "Title of approved Comments filter.")
            case .trashed: return NSLocalizedString("Trashed", comment: "Title of trashed Comments filter.")
            case .spam: return NSLocalizedString("Spam", comment: "Title of spam Comments filter.")
            }
        }
    }

    @objc func configureFilterTabBar(_ filterTabBar: FilterTabBar) {
        WPStyleGuide.configureFilterTabBar(filterTabBar)
        filterTabBar.items = CommentFilter.allCases
        filterTabBar.addTarget(self, action: #selector(selectedFilterDidChange(_:)), for: .valueChanged)
    }

    @objc private func selectedFilterDidChange(_ filterTabBar: FilterTabBar) {
        print("🔴 tab selected: ", filterTabBar.selectedIndex)
    }

}
