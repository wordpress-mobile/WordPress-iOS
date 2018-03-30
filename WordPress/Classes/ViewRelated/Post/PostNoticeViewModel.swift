import UIKit

enum PostNoticeUserInfoKey {
    static let postID = "post_id"
}

struct PostNoticeViewModel {
    let post: AbstractPost

    /// Returns the Notice represented by this view model.
    ///
    var notice: Notice {
        if uploadSuccessful {
            return successNotice
        } else {
            return failureNotice
        }
    }

    private var successNotice: Notice {
        let action = self.action

        return Notice(title: title,
                      message: message,
                      feedbackType: .success,
                      notificationInfo: notificationInfo,
                      actionTitle: action.title,
                      actionHandler: {
                        switch action {
                        case .publish:
                            self.publishPost()
                        case .view:
                            self.viewPost()
                        }
        })
    }

    private var failureNotice: Notice {
        return Notice(title: failureTitle,
                      message: message,
                      feedbackType: .error,
                      notificationInfo: notificationInfo,
                      actionTitle: failureActionTitle,
                      actionHandler: {
                        self.retryUpload()
        })
    }

    private var uploadSuccessful: Bool {
        return post.remoteStatus == .sync
    }

    // MARK: - Display values for Notice

    private var title: String {
        if let page = post as? Page {
            return title(for: page)
        } else {
            return title(for: post)
        }
    }

    private func title(for page: Page) -> String {
        let status = page.status ?? .publish

        switch status {
        case .draft:
            return NSLocalizedString("Page draft uploaded", comment: "Title of notification displayed when a page has been successfully saved as a draft.")
        case .scheduled:
            return NSLocalizedString("Page scheduled", comment: "Title of notification displayed when a page has been successfully scheduled.")
        case .pending:
            return NSLocalizedString("Page pending review", comment: "Title of notification displayed when a page has been successfully saved as a draft.")
        default:
            return NSLocalizedString("Page published", comment: "Title of notification displayed when a page has been successfully published.")
        }
    }

    private func title(for post: AbstractPost) -> String {
        let status = post.status ?? .publish

        switch status {
        case .draft:
            return NSLocalizedString("Post draft uploaded", comment: "Title of notification displayed when a post has been successfully saved as a draft.")
        case .scheduled:
            return NSLocalizedString("Post scheduled", comment: "Title of notification displayed when a post has been successfully scheduled.")
        case .pending:
            return NSLocalizedString("Post pending review", comment: "Title of notification displayed when a post has been successfully saved as a draft.")
        default:
            return NSLocalizedString("Post published", comment: "Title of notification displayed when a post has been successfully published.")
        }
    }

    private var failureTitle: String {
        if post is Page {
            return NSLocalizedString("Page failed to upload", comment: "Title of notification displayed when a page has failed to upload.")
        } else {
            return NSLocalizedString("Post failed to upload", comment: "Title of notification displayed when a post has failed to upload.")
        }
    }

    private var message: String {
        let title = post.postTitle ?? ""
        if title.count > 0 {
            return title
        }

        return post.blog.displayURL as String? ?? ""
    }

    // MARK: - Notifications

    private var notificationInfo: NoticeNotificationInfo {
        var userInfo = [String: Any]()

        if let post = postInContext {
            userInfo[PostNoticeUserInfoKey.postID] = post.objectID.uriRepresentation().absoluteString
        }

        return NoticeNotificationInfo(identifier: UUID().uuidString,
                                      categoryIdentifier: notificationCategoryIdentifier,
                                      title: notificationTitle,
                                      body: notificationBody,
                                      userInfo: userInfo)
    }

    private var notificationCategoryIdentifier: String {
        return uploadSuccessful ? "post-upload-success" : "post-upload-failure"
    }

    var notificationTitle: String {
        if uploadSuccessful {
            let title = post.postTitle ?? ""
            if title.count > 0 {
                return "“\(title)” \(self.title)"
            } else {
                return self.title
            }
        } else {
            return failureTitle
        }
    }

    private var notificationBody: String {
        if uploadSuccessful {
            return post.blog.displayURL as String? ?? ""
        } else {
            return message
        }
    }

    // MARK: - Actions

    private enum Action {
        case publish
        case view

        var title: String {
            switch self {
            case .publish:
                return NSLocalizedString("Publish", comment: "Button title. Publishes a post.")
            case .view:
                return NSLocalizedString("View", comment: "Button title. Displays a summary / sharing screen for a specific post.")
            }
        }
    }

    private var action: Action {
        return (post.status == .draft) ? .publish : .view
    }

    private var failureActionTitle: String {
        return NSLocalizedString("Retry", comment: "Button title. Retries uploading a post.")
    }

    private func viewPost() {
        PostNoticeNavigationCoordinator.presentPostEpilogue(for: post)
    }


    private func publishPost() {
        guard let post = postInContext else {
            return
        }

        post.status = .publish
        PostCoordinator.shared.save(post: post)
    }

    private func retryUpload() {
        guard let post = postInContext else {
            return
        }

        PostCoordinator.shared.save(post: post)
    }

    private var postInContext: AbstractPost? {
        let context = ContextManager.sharedInstance().mainContext
        let objectInContext = try? context.existingObject(with: post.objectID)
        let postInContext = objectInContext as? AbstractPost

        return postInContext
    }
}
