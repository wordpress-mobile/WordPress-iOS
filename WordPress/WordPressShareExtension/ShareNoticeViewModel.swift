enum ShareNoticeUserInfoKey {
    static let blogID = "blog_id"
    static let postID = "post_id"
}

struct ShareNoticeViewModel {
    private let uploadedPost: PostUploadOperation

    init?(postOperation: PostUploadOperation) {
        guard postOperation.currentStatus != .pending, postOperation.currentStatus != .inProgress else {
            return nil
        }
        self.uploadedPost = postOperation
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
                        ShareNoticeNavigationCoordinator.presentEditor(for: post, source: "share_upload_notification")
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
            return NSLocalizedString("Post uploaded", comment: "Title on alert displayed to the user when a single post has been uploaded.")
        } else {
            return NSLocalizedString("Post upload failed", comment: "Title on alert displayed to the user when a single post has failed to upload.")
        }
    }

    var notificationBody: String? {
        if uploadSuccessful {
            return postInContext?.titleForDisplay() ?? NSLocalizedString("1 post successfully shared", comment: "Alert displayed to the user when a single post has been successfully shared.")
        } else {
            return NSLocalizedString("1 post not uploaded", comment: "Alert displayed to the user when a single post item has failed to upload.")
        }
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
