import UIKit

/// Configuration and population of cells in Reader
final class ReaderCellConfiguration {
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

    func configureGapMarker(_ cell: ReaderGapMarkerCell, filling: Bool) {
        cell.animateActivityView(filling)
    }
}
