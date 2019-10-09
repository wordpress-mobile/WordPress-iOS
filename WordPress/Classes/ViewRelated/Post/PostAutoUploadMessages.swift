import Foundation

enum PostAutoUploadMessages {
    static let postWillBePublished = NSLocalizedString("We'll publish the post when your device is back online.",
                                                       comment: "Text displayed in notice after a post if published while offline.")
    static let draftWillBeUploaded = NSLocalizedString("We'll save your draft when your device is back online.",
                                                       comment: "Text displayed in notice after the app fails to upload a draft.")
    static let pageFailedToUpload = NSLocalizedString("Page failed to upload",
                                                      comment: "Title of notification displayed when a page has failed to upload.")
    static let postFailedToUpload = NSLocalizedString("Post failed to upload",
                                                      comment: "Title of notification displayed when a post has failed to upload.")
    static let willAttemptToPublishLater = NSLocalizedString("We couldn't publish this post, but we'll try again later.",
                                                       comment: "Text displayed in notice after the app fails to upload a post, it will attempt to upload it later.")
    static let willNotAttemptToPublishLater = NSLocalizedString("We couldn't complete this action, and didn't publish this post.",
                                                        comment: "Text displayed in notice after the app fails to upload a post, not new attempt will be made.")
    static let willSubmitLater = NSLocalizedString("We'll submit your post for review when your device is back online.",
                                                        comment: "Text displayed in notice after the app fails to upload a post, it will attempt to upload it later.")
    static let willAttemptToSubmitLater = NSLocalizedString("We couldn't submit this post for review, but we'll try again later.",
                                                       comment: "Text displayed in notice after the app fails to upload a post, it will attempt to upload it later.")
    static let willAttemptLater = NSLocalizedString("We couldn't complete this action, but we'll try again later.",
                                                        comment: "Text displayed after the app fails to upload a post, it will attempt to upload it later.")
    static let willNotAttemptToSubmitLater = NSLocalizedString("We couldn't complete this action, and didn't submit this post for review.",
                                                        comment: "Text displayed in notice after the app fails to upload a post, not new attempt will be made.")
    static let privateWillBeUploaded = NSLocalizedString("We'll publish your private post when your device is back online.",
                                                       comment: "Text displayed in notice after the app fails to upload a draft.")
    static let willAttemptToPublishPrivateLater = NSLocalizedString("We couldn't publish this private post, but we'll try again later.",
                                                        comment: "Text displayed after the app fails to upload a private post, it will attempt to upload it later.")
    static let willNotAttemptToPublishPrivateLater = NSLocalizedString("We couldn't complete this action, and didn't publish this private post.",
                                                        comment: "Text displayed after the app fails to upload a private post, no new attempt will be made.")
    static let scheduledWillBeUploaded = NSLocalizedString("We'll schedule your post when your device is back online.",
                                                       comment: "Text displayed after the app fails to upload a scheduled post.")
    static let willAttemptToScheduleLater = NSLocalizedString("We couldn't schedule this post, but we'll try again later.",
                                                        comment: "Text displayed after the app fails to upload a scheduled post, it will attempt to upload it later.")
    static let willNotAttemptToScheduleLater = NSLocalizedString("We couldn't complete this action, and didn't schedule this post.",
                                                        comment: "Text displayed after the app fails to upload a scheduled post, no new attempt will be made.")
    static let willNotAttemptLater = NSLocalizedString("We couldn't complete this action.",
                                                        comment: "Text displayed after the app fails to upload a post, no new attempt will be made.")
    static let changesWillNotBePublished = NSLocalizedString("We won't publish these changes.",
                                                        comment: "Title for notice displayed on canceling auto-upload published post")
    static let changesWillNotBeSubmitted = NSLocalizedString("We won't submit these changes for review.",
                                                         comment: "Title for notice displayed on canceling auto-upload pending post")
    static let changesWillNotBeScheduled = NSLocalizedString("We won't schedule these changes.",
                                                         comment: "Title for notice displayed on canceling auto-upload of a scheduled post")
    static let changesWillNotBeSaved = NSLocalizedString("We won't save the latest changes to your draft.",
                                                         comment: "Title for notice displayed on canceling auto-upload of a draft post")
    static let failedMedia = NSLocalizedString("We couldn't upload this media.",
                                                         comment: "Text displayed if a media couldnt be uploaded.")
    static let failedMediaForPublish = NSLocalizedString("We couldn't upload this media, and didn't publish the post.",
                                                         comment: "Text displayed if a media couldn't be uploaded for a published post.")
    static let failedMediaForPrivate = NSLocalizedString("We couldn't upload this media, and didn't publish this private post.",
                                                         comment: "Text displayed if a media couldn't be uploaded for a private post.")
    static let failedMediaForScheduled = NSLocalizedString("We couldn't upload this media, and didn't schedule this post.",
                                                         comment: "Text displayed if a media couldn't be uploaded for a scheduled post.")
    static let failedMediaForPending = NSLocalizedString("We couldn't upload this media, and didn't submit this post for review.",
                                                         comment: "Text displayed if a media couldn't be uploaded for a pending post.")

    static func cancelMessage(for postStatus: BasePost.Status?) -> String {
        switch postStatus {
        case .publish:
            return PostAutoUploadMessages.changesWillNotBePublished
        case .publishPrivate:
            return PostAutoUploadMessages.changesWillNotBePublished
        case .scheduled:
            return PostAutoUploadMessages.changesWillNotBeScheduled
        case .draft:
            return PostAutoUploadMessages.changesWillNotBeSaved
        default:
            return PostAutoUploadMessages.changesWillNotBeSubmitted
        }
    }

    static func attemptFailures(for post: AbstractPost,
                                withState state: PostAutoUploadInteractor.AutoUploadAttemptState) -> String? {
        switch state {
        case .attempted:
            return PostAutoUploadMessages.willAttemptToAutoUpload(for: post.status)
        case .reachedLimit:
            return post.hasFailedMedia ? PostAutoUploadMessages.failedMedia(for: post.status) : PostAutoUploadMessages.willNotAttemptToAutoUpload(for: post.status)
        default:
            return nil
        }
    }

    static func failedMedia(for postStatus: BasePost.Status?) -> String {
        switch postStatus {
        case .publish:
            return PostAutoUploadMessages.failedMediaForPublish
        case .publishPrivate:
            return PostAutoUploadMessages.failedMediaForPrivate
        case .scheduled:
            return PostAutoUploadMessages.failedMediaForScheduled
        case .pending:
            return PostAutoUploadMessages.failedMediaForPending
        default:
            return PostAutoUploadMessages.failedMedia
        }
    }

    private static func willAttemptToAutoUpload(for postStatus: BasePost.Status?) -> String {
        switch postStatus {
        case .publish:
            return PostAutoUploadMessages.willAttemptToPublishLater
        case .publishPrivate:
            return PostAutoUploadMessages.willAttemptToPublishPrivateLater
        case .scheduled:
            return PostAutoUploadMessages.willAttemptToScheduleLater
        case .pending:
            return PostAutoUploadMessages.willAttemptToSubmitLater
        default:
            return PostAutoUploadMessages.willAttemptLater
        }
    }

    private static func willNotAttemptToAutoUpload(for postStatus: BasePost.Status?) -> String {
        switch postStatus {
        case .publish:
            return PostAutoUploadMessages.willNotAttemptToPublishLater
        case .publishPrivate:
            return PostAutoUploadMessages.willNotAttemptToPublishPrivateLater
        case .scheduled:
            return PostAutoUploadMessages.willNotAttemptToScheduleLater
        case .pending:
            return PostAutoUploadMessages.willNotAttemptToSubmitLater
        default:
            return PostAutoUploadMessages.willNotAttemptLater
        }
    }
}
