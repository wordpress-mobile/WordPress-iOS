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

    func configurePostCardCell(_ cell: UITableViewCell, withPost post: ReaderPost, topic: ReaderAbstractTopic? = nil, delegate: ReaderPostCellDelegate?, loggedInActionVisibility: ReaderActionsVisibility) {
        // To help avoid potential crash: https://github.com/wordpress-mobile/WordPress-iOS/issues/6757
        guard !post.isDeleted else {
            return
        }

        let postCell = cell as! ReaderPostCardCell

        postCell.delegate = delegate

        postCell.loggedInActionVisibility = loggedInActionVisibility
        postCell.configureCell(post)
    }

    func configureGapMarker(_ cell: ReaderGapMarkerCell, filling: Bool) {
        cell.animateActivityView(filling)
    }
}
