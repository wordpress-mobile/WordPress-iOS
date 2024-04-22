import UIKit

extension PostCoordinator {
    static func makeUploadSuccessNotice(for post: AbstractPost, previousStatus: AbstractPost.Status? = nil) -> Notice {
        var message: String {
            let title = post.titleForDisplay() ?? ""
            if !title.isEmpty {
                return title
            }
            return post.blog.displayURL as String? ?? ""
        }
        let isPublished = post.status == .publish
        let isUpdated = post.status == previousStatus
        return Notice(title: Strings.publishSuccessTitle(for: post, isUpdated: isUpdated),
                      message: message,
                      feedbackType: .success,
                      notificationInfo: makeUploadSuccessNotificationInfo(for: post, isUpdated: isUpdated),
                      actionTitle: isPublished ? Strings.view : nil,
                      actionHandler: { _ in
            PostNoticeNavigationCoordinator.presentPostEpilogue(for: post)
        })
    }

    private static func makeUploadSuccessNotificationInfo(for post: AbstractPost, isUpdated: Bool) -> NoticeNotificationInfo {
        let status = Strings.publishSuccessTitle(for: post, isUpdated: isUpdated)
        var title: String {
            let title = post.titleForDisplay() ?? ""
            guard !title.isEmpty else {
                return status
            }
            return "“\(title)” \(status)"
        }
        var body: String {
            post.blog.displayURL as String? ?? ""
        }
        return NoticeNotificationInfo(
            identifier: UUID().uuidString,
            categoryIdentifier: InteractiveNotificationsManager.NoteCategoryDefinition.postUploadSuccess.rawValue,
            title: title,
            body: body,
            userInfo: [
                PostNoticeUserInfoKey.postID: post.objectID.uriRepresentation().absoluteString
            ])
    }
}

private enum Strings {
    static let view = NSLocalizedString("postNotice.view", value: "View", comment: "Button title. Displays a summary / sharing screen for a specific post.")

    static func publishSuccessTitle(for post: AbstractPost, isUpdated: Bool = false) -> String {
        switch post {
        case let post as Post:
            guard !isUpdated else {
                return NSLocalizedString("postNotice.postUpdated", value: "Post updated", comment: "Title of notification displayed when a post has been successfully updated.")
            }
            switch post.status {
            case .draft:
                return NSLocalizedString("postNotice.postDraftCreated", value: "Post draft uploaded", comment: "Title of notification displayed when a post has been successfully saved as a draft.")
            case .scheduled:
                return NSLocalizedString("postNotice.postScheduled", value: "Post scheduled", comment: "Title of notification displayed when a post has been successfully scheduled.")
            case .pending:
                return NSLocalizedString("postNotice.postPendingReview", value: "Post pending review", comment: "Title of notification displayed when a post has been successfully saved as a draft.")
            default:
                return NSLocalizedString("postNotice.postPublished", value: "Post published", comment: "Title of notification displayed when a post has been successfully published.")
            }
        case let page as Page:
            guard !isUpdated else {
                return NSLocalizedString("postNotice.pageUpdated", value: "Page updated", comment: "Title of notification displayed when a page has been successfully updated.")
            }
            switch page.status {
            case .draft:
                return NSLocalizedString("postNotice.pageDraftCreated", value: "Page draft uploaded", comment: "Title of notification displayed when a page has been successfully saved as a draft.")
            case .scheduled:
                return NSLocalizedString("postNotice.pageScheduled", value: "Page scheduled", comment: "Title of notification displayed when a page has been successfully scheduled.")
            case .pending:
                return NSLocalizedString("postNotice.pagePending", value: "Page pending review", comment: "Title of notification displayed when a page has been successfully saved as a draft.")
            default:
                return NSLocalizedString("postNotice.pagePublished", value: "Page published", comment: "Title of notification displayed when a page has been successfully published.")
            }
        default:
            assertionFailure("Unexpected post type: \(post)")
            return ""
        }
    }
}
