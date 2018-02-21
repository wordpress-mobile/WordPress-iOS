import UIKit

/// Encapsulates status display logic for PostCardTableViewCells.
///
class PostCardStatusViewModel: NSObject {
    private let post: Post

    @objc
    init(post: Post) {
        self.post = post
        super.init()
    }

    @objc
    var status: String? {
        return post.statusForDisplay()
    }

    @objc
    var shouldHideStatusView: Bool {
        guard let status = status else {
            return true
        }

        return status.count == 0
    }

    @objc
    var statusImage: UIImage? {
        guard let status = post.status else {
            return nil
        }

        switch status {
        case .pending:
            return UIImage(named: "icon-post-status-pending")
        case .scheduled:
            return UIImage(named: "icon-post-status-scheduled")
        case .trash:
            return UIImage(named: "icon-post-status-trashed")
        default:
            return UIImage(named: "icon-post-status-pending")
        }
    }

    @objc
    var statusColor: UIColor {
        guard let status = post.status else {
            return WPStyleGuide.grey()
        }

        switch status {
        case .pending:
            return WPStyleGuide.jazzyOrange()
        case .scheduled:
            return WPStyleGuide.wordPressBlue()
        case .trash:
            return WPStyleGuide.errorRed()
        default:
            return WPStyleGuide.jazzyOrange()
        }
    }
}
