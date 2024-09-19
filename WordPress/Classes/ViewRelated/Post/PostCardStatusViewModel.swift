import UIKit
import Gridicons

/// Encapsulates status display logic for PostCardTableViewCells.
///
class PostCardStatusViewModel: NSObject, AbstractPostMenuViewModel {

    let post: Post

    private let isJetpackFeaturesEnabled: Bool
    private let isBlazeFlagEnabled: Bool

    init(post: Post,
         isJetpackFeaturesEnabled: Bool = JetpackFeaturesRemovalCoordinator.jetpackFeaturesEnabled(),
         isBlazeFlagEnabled: Bool = BlazeHelper.isBlazeFlagEnabled()) {
        self.post = post
        self.isJetpackFeaturesEnabled = isJetpackFeaturesEnabled
        self.isBlazeFlagEnabled = isBlazeFlagEnabled
        super.init()
    }

    var status: String? {
        if post.isLegacyUnsavedRevision {
            return StatusMessages.localChanges
        }
        return nil
    }

    var author: String {
        guard let author = post.authorForDisplay() else {
            return ""
        }

        return author
    }

    var statusColor: UIColor {
        if post.isLegacyUnsavedRevision {
            return UIAppColor.warning
        }
        switch post.status ?? .draft {
        case .trash:
            return UIAppColor.error
        default:
            return .secondaryLabel
        }
    }

    /// Returns what buttons are visible
    var buttonSections: [AbstractPostButtonSection] {
        return [
            createPrimarySection(),
            createNavigationSection(),
            createTrashSection(),
            createUploadStatusSection()
        ]
    }

    private func createPrimarySection() -> AbstractPostButtonSection {
        var buttons = [AbstractPostButton]()

        if post.status != .trash {
            buttons.append(.view)
        }

        if canPublish {
            buttons.append(.publish)
        }

        if post.status != .draft {
            buttons.append(.moveToDraft)
        }

        if post.status == .publish || post.status == .draft || post.status == .pending {
            buttons.append(.duplicate)
        }

        if post.status == .publish && post.hasRemote() {
            buttons.append(.share)
        }
        return AbstractPostButtonSection(buttons: buttons)
    }

    private func createNavigationSection() -> AbstractPostButtonSection {
        var buttons = [AbstractPostButton]()

        if isBlazeFlagEnabled && post.canBlaze {
            BlazeEventsTracker.trackEntryPointDisplayed(for: .postsList)
            buttons.append(.blaze)
        }

        if isJetpackFeaturesEnabled, post.status == .publish && post.hasRemote() {
            buttons.append(contentsOf: [.stats, .comments])
        }
        if post.status != .trash {
            buttons.append(.settings)
        }

        return AbstractPostButtonSection(buttons: buttons)
    }

    private func createTrashSection() -> AbstractPostButtonSection {
        let action: AbstractPostButton = post.original().status == .trash ? .delete : .trash
        return AbstractPostButtonSection(buttons: [action])
    }

    private func createUploadStatusSection() -> AbstractPostButtonSection {
        guard let error = PostCoordinator.shared.syncError(for: post.original()) else {
            return AbstractPostButtonSection(buttons: [])
        }
        return AbstractPostButtonSection(title: error.localizedDescription, buttons: [.retry])
    }

    private var canPublish: Bool {
        let userCanPublish = post.blog.capabilities != nil ? post.blog.isPublishingPostsAllowed() : true
        return (post.status == .draft || post.status == .pending) && userCanPublish
    }

    func statusAndBadges(separatedBy separator: String) -> String {
        let sticky = post.isStickyPost ? Constants.stickyLabel : ""
        let pending = post.status == .pending ? Constants.pendingReview : ""
        let visibility: String = {
            let visibility = PostVisibility(post: post)
            switch visibility {
            case .public:
                return ""
            case .private, .protected:
                return visibility.localizedTitle
            }
        }()
        let status = self.status ?? ""

        return [status, visibility, pending, sticky].filter { !$0.isEmpty }.joined(separator: separator)
    }

    private enum Constants {
        static let stickyLabel = NSLocalizedString("Sticky", comment: "Label text that defines a post marked as sticky")
        static let pendingReview = NSLocalizedString("postList.badgePendingReview", value: "Pending review", comment: "Badge for post cells")
    }

    enum StatusMessages {
        static let localChanges = NSLocalizedString("Local changes", comment: "A status label for a post that only exists on the user's iOS device, and has not yet been published to their blog.")
    }
}
