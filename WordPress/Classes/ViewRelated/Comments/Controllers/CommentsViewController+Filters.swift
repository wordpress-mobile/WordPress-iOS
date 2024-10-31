extension CommentsViewController {

    enum CommentFilter: Int, FilterTabBarItem, CaseIterable {
        case all
        case pending
        case unreplied
        case approved
        case spam
        case trashed

        var title: String {
            switch self {
            case .all: return NSLocalizedString("All", comment: "Title of all Comments filter.")
            case .pending: return NSLocalizedString("Pending", comment: "Title of pending Comments filter.")
            case .unreplied: return NSLocalizedString("Unreplied", comment: "Title of unreplied Comments filter.")
            case .approved: return NSLocalizedString("Approved", comment: "Title of approved Comments filter.")
            case .spam: return NSLocalizedString("Spam", comment: "Title of spam Comments filter.")
            case .trashed: return NSLocalizedString("Trashed", comment: "Title of trashed Comments filter.")
            }
        }

        var analyticsTitle: String {
            switch self {
            case .all: return "All"
            case .pending: return "Pending"
            case .unreplied: return "Unreplied"
            case .approved: return "Approved"
            case .spam: return "Spam"
            case .trashed: return "Trashed"
            }
        }

        var statusFilter: CommentStatusFilter {
            switch self {
            case .all: return CommentStatusFilterAll
            case .pending: return CommentStatusFilterUnapproved
            case .unreplied: return CommentStatusFilterAll
            case .approved: return CommentStatusFilterApproved
            case .spam: return CommentStatusFilterSpam
            case .trashed: return CommentStatusFilterTrash
            }
        }
    }

    @objc func configureFilterTabBar(_ filterTabBar: FilterTabBar) {
        WPStyleGuide.configureFilterTabBar(filterTabBar)
        filterTabBar.items = CommentFilter.allCases
        filterTabBar.addTarget(self, action: #selector(selectedFilterDidChange(_:)), for: .valueChanged)
    }

    @objc private func selectedFilterDidChange(_ filterTabBar: FilterTabBar) {
        guard let filter = CommentFilter(rawValue: filterTabBar.selectedIndex) else {
            return
        }

        WPAnalytics.track(.commentFilterChanged, properties: ["selected_filter": filter.analyticsTitle])
        refresh(with: filter.statusFilter)
    }

    @objc func getSelectedIndex(_ filterTabBar: FilterTabBar) -> Int {
        return filterTabBar.selectedIndex
    }

    @objc func setSeletedIndex(_ selectedIndex: Int, filterTabBar: FilterTabBar) {
        filterTabBar.setSelectedIndex(selectedIndex, animated: false)
        selectedFilterDidChange(filterTabBar)
    }

    @objc func isUnrepliedFilterSelected(_ filterTabBar: FilterTabBar) -> Bool {
        guard let item = filterTabBar.currentlySelectedItem as? CommentFilter else {
            return false
        }
        return item == CommentFilter.unreplied
    }
}
