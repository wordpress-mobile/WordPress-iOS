enum ShareNoticeUserInfoKey {
    static let blogID = "blog_id"
    static let postID = "post_id"
}

struct ShareNoticeViewModel {
    private let uploadedPost: PostUploadOperation
    private let uploadedMedia: [MediaUploadOperation]?

    init?(postOperation: PostUploadOperation, mediaOperations: [MediaUploadOperation]? = nil) {
        guard postOperation.currentStatus != .pending, postOperation.currentStatus != .inProgress else {
            return nil
        }
        self.uploadedPost = postOperation
        self.uploadedMedia = mediaOperations
    }

    private var uploadSuccessful: Bool {
        return uploadedPost.currentStatus == .complete
    }

    var notice: Notice? {
        if uploadSuccessful {
            return successNotice
        } else {
            return failureNotice
        }
    }

    private var successNotice: Notice {
        guard let post = postInContext else {
            return Notice(title: notificationTitle, message: notificationBody, notificationInfo: notificationInfo)
        }

        return Notice(title: notificationTitle,
                      message: notificationBody,
                      feedbackType: .success,
                      notificationInfo: notificationInfo,
                      actionTitle: NSLocalizedString("Edit Post", comment: "Button title. Opens the editor to edit an existing post."),
                      actionHandler: {
                        ShareNoticeNavigationCoordinator.presentEditor(for: post, source: "share_success_notification")
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
            userInfo[ShareNoticeUserInfoKey.postID] = post.objectID.uriRepresentation().absoluteString
            userInfo[ShareNoticeUserInfoKey.blogID] = post.blog.objectID.uriRepresentation().absoluteString
        }

        return NoticeNotificationInfo(identifier: UUID().uuidString,
                                      categoryIdentifier: notificationCategoryIdentifier,
                                      title: notificationTitle,
                                      body: notificationBody,
                                      userInfo: userInfo)
    }

    private var notificationCategoryIdentifier: String {
        return uploadSuccessful ? "share-upload-success" : "share-upload-failure"
    }

    var notificationTitle: String {
        if uploadSuccessful {
            return successfulDescription
        } else {
            return failedDescription
        }
    }

    var notificationBody: String {
        let dateString = postInContext?.dateForDisplay()?.mediumString() ?? Date().mediumString()
        return "\(dateString)."
    }

    private var successfulDescription: String {
        guard let uploadedMedia = uploadedMedia else {
            return NSLocalizedString("1 post uploaded.", comment: "Alert displayed to the user when a single post has been successfully uploaded.")
        }

        return pluralize(uploadedMedia.count,
                         singular: NSLocalizedString("Successfully uploaded 1 post, 1 file.", comment: "System notification displayed to the user when a single post and 1 file has uploaded successfully."),
                         plural: NSLocalizedString("Successfully uploaded 1 post, %ld files.", comment: "System notification displayed to the user when a single post and multiple files have uploaded successfully."))
    }

    private var failedDescription: String {
        guard let uploadedMedia = uploadedMedia else {
            return NSLocalizedString("Unable to upload 1 post.", comment: "Alert displayed to the user when a single post has failed to upload.")
        }

        return pluralize(uploadedMedia.count,
                         singular: NSLocalizedString("Unable to upload 1 post, 1 file.", comment: "Alert displayed to the user when a single post and 1 file has failed to upload."),
                         plural: NSLocalizedString("Unable to upload 1 post, %ld files.", comment: "Alert displayed to the user when a single post and multiple files have failed to upload."))
    }

    private var postInContext: Post? {
        let context = ContextManager.sharedInstance().mainContext
        let blogService = BlogService(managedObjectContext: context)

        guard uploadedPost.remotePostID > 0,
            uploadedPost.siteID > 0,
            let blog = blogService.blog(byBlogId: NSNumber(value: uploadedPost.siteID)) else {
            return nil
        }

        let postID = NSNumber(value: uploadedPost.remotePostID)
        let postService = PostService(managedObjectContext: context)
        guard let post = postService.findPost(withID: postID, in: blog) as? Post else {
            return nil
        }

        return post
    }
}

/// Helper method to provide the singular or plural (formatted) version of a
/// string based on a count.
///
private func pluralize(_ count: Int, singular: String, plural: String) -> String {
    if count == 1 {
        return singular
    } else {
        return String(format: plural, count)
    }
}
