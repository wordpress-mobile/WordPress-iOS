import UIKit

enum PostNoticeUserInfoKey {
    static let postID = "post_id"
}

struct PostNoticeViewModel {
    private let post: AbstractPost
    private let postCoordinator: PostCoordinator
    private let autoUploadInteractor = PostAutoUploadInteractor()
    private let isInternetReachable: Bool

    init(post: AbstractPost, postCoordinator: PostCoordinator = PostCoordinator.shared, isInternetReachable: Bool = ReachabilityUtils.isInternetReachable()) {
        self.post = post
        self.postCoordinator = postCoordinator
        self.isInternetReachable = isInternetReachable
    }

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
                      actionHandler: { _ in
                        switch action {
                        case .publish:
                            self.publishPost()
                        case .view:
                            self.viewPost()
                        }
        })
    }

    private var failureNotice: Notice {
        let failureAction = self.failureAction

        return Notice(title: failureTitle,
                      message: message,
                      feedbackType: .error,
                      notificationInfo: notificationInfo,
                      actionTitle: failureAction.title,
                      actionHandler: { _ in
                        switch failureAction {
                        case .cancel:
                            self.cancelAutoUpload()
                        case .retry:
                            self.retryUpload()
                        }
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
            if page.isFirstTimePublish {
                return NSLocalizedString("Page published", comment: "Title of notification displayed when a page has been successfully published.")
            } else {
                return NSLocalizedString("Page updated", comment: "Title of notification displayed when a page has been successfully updated.")
            }
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
            if post.isFirstTimePublish {
                return NSLocalizedString("Post published", comment: "Title of notification displayed when a post has been successfully published.")
            } else {
                return NSLocalizedString("Post updated", comment: "Title of notification displayed when a post has been successfully updated.")
            }
        }
    }

    private var failureTitle: String {

        let postAutoUploadMessages = PostAutoUploadMessages(for: post)

        return postAutoUploadMessages.failedUploadMessage(
            isInternetReachable: isInternetReachable,
            autoUploadState: autoUploadInteractor.autoUploadAttemptState(of: post),
            autoUploadAction: autoUploadInteractor.autoUploadAction(for: post))
    }

    private var message: String {
        let title = post.titleForDisplay() ?? ""
        if !title.isEmpty {
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

    private enum FailureAction {
        case retry
        case cancel

        var title: String {
            switch self {
            case .retry:
                return FailureActionTitles.retry
            case .cancel:
                return FailureActionTitles.cancel
            }
        }
    }

    private var action: Action {
        return (post.status == .draft) ? .publish : .view
    }

    private var failureAction: FailureAction {
        return autoUploadInteractor.canCancelAutoUpload(of: post) && !isInternetReachable ? .cancel : .retry
    }

    // MARK: - Action Handlers

    private func viewPost() {
        PostNoticeNavigationCoordinator.presentPostEpilogue(for: post)
    }

    private func publishPost() {
        guard let post = postInContext else {
            return
        }

        post.status = .publish
        post.shouldAttemptAutoUpload = true
        post.isFirstTimePublish = true
        postCoordinator.save(post)
    }

    private func retryUpload() {
        guard let post = postInContext else {
            return
        }

        postCoordinator.save(post)
    }

    private func cancelAutoUpload() {
        guard let post = postInContext else {
            return
        }

        postCoordinator.cancelAutoUploadOf(post)
    }

    private var postInContext: AbstractPost? {
        let context = ContextManager.sharedInstance().mainContext
        let objectInContext = try? context.existingObject(with: post.objectID)
        let postInContext = objectInContext as? AbstractPost

        return postInContext
    }

    enum FailureActionTitles {
        static let retry = NSLocalizedString("Retry", comment: "Button title. Retries uploading a post.")
        static let cancel = NSLocalizedString("Cancel", comment: "Button title. Cancels automatic uploading of the post when the device is back online.")
    }
}
