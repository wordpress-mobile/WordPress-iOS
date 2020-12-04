/// Configuration and population of cells in Reader
final class ReaderCellConfiguration {
    func configureCrossPostCell(_ cell: ReaderCrossPostCell, withContent content: ReaderTableContent, atIndexPath indexPath: IndexPath) {
        if content.isNull {
            return
        }
        cell.accessoryType = .none
        cell.selectionStyle = .none

        guard let posts = content.content as? [ReaderPost] else {
            return
        }

        let post = posts[indexPath.row]
        cell.configureCell(post)
    }

    func configureBlockedCell(_ cell: ReaderBlockedSiteCell, withContent content: ReaderTableContent, atIndexPath indexPath: IndexPath) {
        if content.isNull {
            return
        }
        cell.accessoryType = .none
        cell.selectionStyle = .none

        guard let posts = content.content as? [ReaderPost] else {
            return
        }
        let post = posts[indexPath.row]
        cell.setSiteName(post.blogName)
    }

    func configurePostCardCell(_ cell: UITableViewCell,
                               withPost post: ReaderPost,
                               topic: ReaderAbstractTopic? = nil,
                               delegate: ReaderPostCellDelegate?,
                               loggedInActionVisibility: ReaderActionsVisibility,
                               topicChipsDelegate: ReaderTopicsChipsDelegate? = nil,
                               displayTopics: Bool = true) {
        // To help avoid potential crash: https://github.com/wordpress-mobile/WordPress-iOS/issues/6757
        guard !post.isDeleted else {
            return
        }

        guard let postCell = cell as? ReaderPostCardCell else {
            return
        }

        postCell.delegate = delegate
        postCell.topicChipsDelegate = topicChipsDelegate

        postCell.loggedInActionVisibility = loggedInActionVisibility
        postCell.displayTopics = displayTopics
        postCell.isWPForTeams = post.blog?.isWPForTeams() ?? false
        postCell.configureCell(post)
        postCell.layoutIfNeeded()
    }

    func configureGapMarker(_ cell: ReaderGapMarkerCell, filling: Bool) {
        cell.animateActivityView(filling)
    }
}
