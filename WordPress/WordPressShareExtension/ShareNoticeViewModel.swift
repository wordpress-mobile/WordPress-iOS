struct ShareNoticeViewModel {
    private let uploadedPost: PostUploadOperation
    private let postInContext: Post?
    private let uploadedMedia: [MediaUploadOperation]?

    init?(postOperation: PostUploadOperation, post: Post?, mediaOperations: [MediaUploadOperation]? = nil) {
        guard postOperation.currentStatus != .pending, postOperation.currentStatus != .inProgress else {
            return nil
        }
        self.uploadedPost = postOperation
        self.uploadedMedia = mediaOperations
        self.postInContext = post
    }

    var notice: Notice? {
        if uploadSuccessful {
            return successNotice
        } else {
            return failureNotice
        }
    }

    // MARK: - Private Vars

    private var uploadSuccessful: Bool {
        return uploadedPost.currentStatus == .complete
    }

    private var successNotice: Notice {
        guard let post = postInContext else {
            return Notice(title: notificationTitle, message: notificationBody, notificationInfo: notificationInfo)
        }

        return Notice(title: notificationTitle,
                      message: notificationBody,
                      feedbackType: .success,
                      notificationInfo: notificationInfo,
                      actionTitle: ShareNoticeText.actionEditPost,
                      actionHandler: {
                        ShareNoticeNavigationCoordinator.presentEditor(for: post, source: ShareNoticeConstants.notificationSourceSuccess)
        })
    }

    private var failureNotice: Notice {
        return Notice(title: notificationTitle,
                      message: notificationBody,
                      feedbackType: .error,
                      notificationInfo: notificationInfo)
    }

    private var notificationInfo: NoticeNotificationInfo {
        var userInfo = [String: Any]()

        if let post = postInContext {
            userInfo[ShareNoticeUserInfoKey.postID] = post.postID
            userInfo[ShareNoticeUserInfoKey.blogID] = post.blog.dotComID?.stringValue
        }

        return NoticeNotificationInfo(identifier: UUID().uuidString,
                                      categoryIdentifier: notificationCategoryIdentifier,
                                      title: notificationTitle,
                                      body: notificationBody,
                                      userInfo: userInfo)
    }

    private var notificationCategoryIdentifier: String {
        return uploadSuccessful ? ShareNoticeConstants.categorySuccessIdentifier : ShareNoticeConstants.categoryFailureIdentifier
    }

    private var notificationTitle: String {
        if uploadSuccessful {
            return successfulTitle
        } else {
            return failedTitle
        }
    }

    private var successfulTitle: String {
        guard let uploadedMedia = uploadedMedia else {
            return ShareNoticeText.successTitleDefault
        }

        return ShareNoticeText.successTitle(mediaItemCount: uploadedMedia.count)
    }

    private var failedTitle: String {
        guard let uploadedMedia = uploadedMedia else {
            return ShareNoticeText.failureTitleDefault
        }

        return ShareNoticeText.failureTitle(mediaItemCount: uploadedMedia.count)
    }

    private var notificationBody: String {
        let dateString = postInContext?.dateForDisplay()?.mediumString() ?? Date().mediumString()
        return "\(dateString)."
    }
}
