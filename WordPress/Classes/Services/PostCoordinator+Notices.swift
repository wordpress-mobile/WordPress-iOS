import UIKit

extension PostCoordinator {
    static func makePublishSuccessNotice(for post: AbstractPost) -> Notice {
        var message: String {
            let title = post.titleForDisplay() ?? ""
            if !title.isEmpty {
                return title
            }
            return post.blog.displayURL as String? ?? ""
        }
        return Notice(title: Strings.publishSuccessTitle(for: post),
                      message: message,
                      feedbackType: .success,
                      notificationInfo: makePublishSuccessNotificationInfo(for: post),
                      actionTitle: Strings.view,
                      actionHandler: { _ in
            PostNoticeNavigationCoordinator.presentPostEpilogue(for: post)
        })
    }

    private static func makePublishSuccessNotificationInfo(for post: AbstractPost) -> NoticeNotificationInfo {
        var title: String {
            let title = post.titleForDisplay() ?? ""
            guard !title.isEmpty else {
                return Strings.publishSuccessTitle(for: post)
            }
            return "“\(title)” \(Strings.publishSuccessTitle(for: post))"
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

    static func makePublishFailureNotice(for post: AbstractPost, error: Error) -> Notice {
        return Notice(
            title: Strings.uploadFailed,
            message: error.localizedDescription,
            feedbackType: .error,
            notificationInfo: makePublishFailureNotificationInfo(for: post, error: error)
        )
    }

    private static func makePublishFailureNotificationInfo(for post: AbstractPost, error: Error) -> NoticeNotificationInfo {
        var title: String {
            let title = post.titleForDisplay() ?? ""
            guard !title.isEmpty else {
                return Strings.uploadFailed
            }
            return "“\(title)” \(Strings.uploadFailed)"
        }
        return NoticeNotificationInfo(
            identifier: UUID().uuidString,
            categoryIdentifier: nil,
            title: title,
            body: error.localizedDescription
        )
    }
}

private enum Strings {
    static let view = NSLocalizedString("postNotice.view", value: "View", comment: "Button title. Displays a summary / sharing screen for a specific post.")

    static let uploadFailed = NSLocalizedString("postNotice.uploadFailed", value: "Upload failed", comment: "A post upload failed notification.")

    static func publishSuccessTitle(for post: AbstractPost, isFirstTimePublish: Bool = true) -> String {
        switch post {
        case let post as Post:
            switch post.status {
            case .draft:
                return NSLocalizedString("postNotice.postDraftCreated", value: "Post draft uploaded", comment: "Title of notification displayed when a post has been successfully saved as a draft.")
            case .scheduled:
                return NSLocalizedString("postNotice.postScheduled", value: "Post scheduled", comment: "Title of notification displayed when a post has been successfully scheduled.")
            case .pending:
                return NSLocalizedString("postNotice.postPendingReview", value: "Post pending review", comment: "Title of notification displayed when a post has been successfully saved as a draft.")
            default:
                if isFirstTimePublish {
                    return NSLocalizedString("postNotice.postPublished", value: "Post published", comment: "Title of notification displayed when a post has been successfully published.")
                } else {
                    return NSLocalizedString("postNotice.postUpdated", value: "Post updated", comment: "Title of notification displayed when a post has been successfully updated.")
                }
            }
        case let page as Page:
            switch page.status {
            case .draft:
                return NSLocalizedString("postNotice.pageDraftCreated", value: "Page draft uploaded", comment: "Title of notification displayed when a page has been successfully saved as a draft.")
            case .scheduled:
                return NSLocalizedString("postNotice.pageScheduled", value: "Page scheduled", comment: "Title of notification displayed when a page has been successfully scheduled.")
            case .pending:
                return NSLocalizedString("postNotice.pagePending", value: "Page pending review", comment: "Title of notification displayed when a page has been successfully saved as a draft.")
            default:
                if isFirstTimePublish {
                    return NSLocalizedString("postNotice.pagePublished", value: "Page published", comment: "Title of notification displayed when a page has been successfully published.")
                } else {
                    return NSLocalizedString("postNotice.pageUpdated", value: "Page updated", comment: "Title of notification displayed when a page has been successfully updated.")
                }
            }
        default:
            assertionFailure("Unexpected post type: \(post)")
            return ""
        }
    }
}
