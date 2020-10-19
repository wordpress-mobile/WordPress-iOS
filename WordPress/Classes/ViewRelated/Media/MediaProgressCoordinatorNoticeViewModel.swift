enum MediaNoticeUserInfoKey {
    static let blogID = "blog_id"
    static let failedMediaIDs = "failed_media_ids"
    static let mediaIDs = "media_ids"
}

struct MediaProgressCoordinatorNoticeViewModel {
    static let uploadErrorNoticeTag: Notice.Tag = "MediaProgressCoordinatorNoticeViewModel.UploadError"

    private let mediaProgressCoordinator: MediaProgressCoordinator
    private let successfulMedia: [Media]
    private let failedMedia: [Media]

    // Is the media progress related to a post?
    // Only failed post media should be reported through this view model.
    // Successful post media uploads should be reported via a PostNoticeViewModel.
    private let isPostMedia: Bool

    init?(mediaProgressCoordinator: MediaProgressCoordinator, isPostMedia: Bool = false) {
        guard !mediaProgressCoordinator.isRunning else {
                return nil
        }

        self.mediaProgressCoordinator = mediaProgressCoordinator
        self.isPostMedia = isPostMedia

        successfulMedia = mediaProgressCoordinator.successfulMedia
        failedMedia = mediaProgressCoordinator.failedMedia

        guard successfulMedia.count + failedMedia.count > 0 else {
            return nil
        }
    }

    private var uploadSuccessful: Bool {
        return !mediaProgressCoordinator.hasFailedMedia
    }

    var notice: Notice? {
        if uploadSuccessful {
            return successNotice
        } else {
            return failureNotice
        }
    }

    private var successNotice: Notice {
        guard let blog = blogInContext else {
            return Notice(title: title, notificationInfo: notificationInfo)
        }

        return Notice(title: title,
                      feedbackType: .success,
                      notificationInfo: notificationInfo,
                      actionTitle: actionTitle,
                      actionHandler: { _ in
                        MediaNoticeNavigationCoordinator.presentEditor(for: blog, source: "media_upload_notice", media: self.successfulMedia)
        })
    }

    private var failureNotice: Notice {
        return Notice(title: title,
                      message: message,
                      feedbackType: .error,
                      notificationInfo: notificationInfo,
                      actionTitle: NSLocalizedString("Retry", comment: "User action to retry media upload."),
                      tag: MediaProgressCoordinatorNoticeViewModel.uploadErrorNoticeTag,
                      actionHandler: { _ in
                        for media in self.failedMedia {
                            MediaCoordinator.shared.retryMedia(media)
                        }
        })
    }

    private var notificationInfo: NoticeNotificationInfo {
        var userInfo = [String: Any]()

        if let blog = blogInContext {
            userInfo[MediaNoticeUserInfoKey.blogID] = blog.objectID.uriRepresentation().absoluteString
        }

        if uploadSuccessful {
            userInfo[MediaNoticeUserInfoKey.mediaIDs] = successfulMedia.map({ $0.objectID.uriRepresentation().absoluteString })
        } else {
            userInfo[MediaNoticeUserInfoKey.failedMediaIDs] = failedMedia.map({ $0.objectID.uriRepresentation().absoluteString })
        }

        return NoticeNotificationInfo(identifier: UUID().uuidString,
                                      categoryIdentifier: notificationCategoryIdentifier,
                                      title: notificationTitle,
                                      body: notificationBody,
                                      userInfo: userInfo)
    }

    private var notificationCategoryIdentifier: String {
        return uploadSuccessful ? "media-upload-success" : "media-upload-failure"
    }

    var title: String {
        if uploadSuccessful {
            return pluralize(successfulMedia.count,
                             singular: NSLocalizedString("Media uploaded (1 file)", comment: "Alert displayed to the user when a single media item has uploaded successfully."),
                             plural: NSLocalizedString("Media uploaded (%ld files)", comment: "Alert displayed to the user when multiple media items have uploaded successfully."))
        } else {
            return failedMediaDescription
        }
    }

    var message: String? {
        guard !uploadSuccessful && successfulMedia.count >= 1 else {
            return nil
        }

        return successfulUploadsDescription
    }

    var notificationTitle: String {
        if uploadSuccessful {
            return successfulUploadsDescription
        } else {
            return NSLocalizedString("Upload failed", comment: "System notification displayed to the user when media files have failed to upload.")
        }
    }

    var notificationBody: String? {
        if uploadSuccessful {
            return blogInContext?.hostname as String?
        } else {
            return failedMediaDescription
        }
    }

    private var successfulUploadsDescription: String {
        return pluralize(successfulMedia.count,
                         singular: NSLocalizedString("1 file successfully uploaded", comment: "System notification displayed to the user when a single media item has uploaded successfully."),
                         plural: NSLocalizedString("%ld files successfully uploaded", comment: "System notification displayed to the user when multiple media items have uploaded successfully."))
    }

    private var failedMediaDescription: String {
        if isPostMedia {
            return pluralize(mediaProgressCoordinator.failedMediaIDs.count,
                             singular: NSLocalizedString("1 file not uploaded", comment: "Alert displayed to the user when a single media item has failed to upload."),
                             plural: NSLocalizedString("%ld files not uploaded", comment: "Alert displayed to the user when multiple media items have failed to upload."))
        } else {
            return pluralize(mediaProgressCoordinator.failedMediaIDs.count,
                             singular: NSLocalizedString("1 post, 1 file not uploaded", comment: "Alert displayed to the user when a single media item attached to a post has failed to upload."),
                             plural: NSLocalizedString("1 post, %ld files not uploaded", comment: "Alert displayed to the user when multiple media items attached to a post have failed to upload."))
        }
    }

    var actionTitle: String {
        if uploadSuccessful {
            return NSLocalizedString("Write Post", comment: "Button title. Opens the editor to write a new post.")
        } else {
            return NSLocalizedString("Retry", comment: "Button title, displayed when media has failed to upload. Allows the user to try the upload again.")
        }
    }

    private var blogInContext: Blog? {
        guard let mediaID = mediaProgressCoordinator.inProgressMediaIDs.first,
            let media = mediaProgressCoordinator.media(withIdentifier: mediaID) else {
                return nil
        }

        let context = ContextManager.sharedInstance().mainContext
        var blog: Blog? = nil

        context.performAndWait {
            guard let mediaInContext = try? context.existingObject(with: media.objectID) as? Media else {
                DDLogError("The media object no longer exists")
                return
            }

            blog = mediaInContext.blog
        }

        return blog
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
