import UIKit
import Gridicons

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

    private var postStatus: BasePost.Status? {
        return post.status
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
        guard let status = postStatus else {
            return nil
        }

        switch status {
        case .pending:
            return Gridicon.iconOfType(.chat)
        case .scheduled:
            return Gridicon.iconOfType(.scheduled)
        case .trash:
            return Gridicon.iconOfType(.trash)
        default:
            return UIDevice.isPad() ? Gridicon.iconOfType(.tablet) : Gridicon.iconOfType(.phone)
        }
    }

    @objc
    var statusColor: UIColor {
        guard let status = postStatus else {
            return WPStyleGuide.darkGrey()
        }

        switch status {
        case .pending:
            return WPStyleGuide.validGreen()
        case .scheduled:
            return WPStyleGuide.mediumBlue()
        case .trash:
            return WPStyleGuide.errorRed()
        default:
            return WPStyleGuide.darkGrey()
        }
    }

    @objc
    var shouldHideProgressView: Bool {
        return true
    }
}
