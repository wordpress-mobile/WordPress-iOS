struct ShareNoticeViewModel {
    private let postInContext: Post?
    private let uploadStatus: UploadOperation.UploadStatus
    private let uploadedMediaCount: Int
    private let postStatus: Post.Status?

    init?(post: Post?, uploadStatus: UploadOperation.UploadStatus, uploadedMediaCount: Int = 0) {
        guard uploadStatus != .pending, uploadStatus != .inProgress else {
            return nil
        }

        self.postInContext = post
        self.uploadStatus = uploadStatus
        self.uploadedMediaCount = uploadedMediaCount
        self.postStatus = post?.status
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
        return uploadStatus == .complete
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
                      actionHandler: { _ in
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
        userInfo[ShareNoticeUserInfoKey.originatedFromAppExtension] = false

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
        if uploadedMediaCount == 0 && postStatus != .draft {
            return ShareNoticeText.successTitleDefault
        }

        return ShareNoticeText.successTitle(mediaItemCount: uploadedMediaCount, postStatus: (postStatus?.rawValue)!)
    }

    private var failedTitle: String {
        if uploadedMediaCount == 0 {
            return ShareNoticeText.failureTitleDefault
        }

        return ShareNoticeText.failureTitle(mediaItemCount: uploadedMediaCount)
    }

    private var notificationBody: String {
        return postInContext?.dateForDisplay()?.toMediumString() ?? Date().toMediumString()
    }
}
