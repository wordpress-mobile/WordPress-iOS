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

        var statusFilter: CommentStatusFilter {
            switch self {
            case .all: return CommentStatusFilterAll
            case .pending: return CommentStatusFilterUnapproved
            case .approved: return CommentStatusFilterApproved
            case .trashed: return CommentStatusFilterTrash
            case .spam: return CommentStatusFilterSpam
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

        WPAnalytics.track(.commentFilterChanged, properties: ["selected_filter": filter.title])
        refresh(with: filter.statusFilter)
    }

    @objc func getSelectedIndex(_ filterTabBar: FilterTabBar) -> Int {
        return filterTabBar.selectedIndex
    }

    @objc func setSeletedIndex(_ selectedIndex: Int, filterTabBar: FilterTabBar) {
        filterTabBar.setSelectedIndex(selectedIndex, animated: false)
        selectedFilterDidChange(filterTabBar)
    }
}
