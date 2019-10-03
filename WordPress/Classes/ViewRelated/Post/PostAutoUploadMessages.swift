import Foundation

enum PostAutoUploadMessages {
    static let postWillBePublished = NSLocalizedString("Post will be published next time your device is online",
                                                       comment: "Text displayed in notice after a post if published while offline.")
    static let draftWillBeUploaded = NSLocalizedString("Draft will be uploaded next time your device is online",
                                                       comment: "Text displayed in notice after the app fails to upload a draft.")
    static let pageFailedToUpload = NSLocalizedString("Page failed to upload",
                                                      comment: "Title of notification displayed when a page has failed to upload.")
    static let postFailedToUpload = NSLocalizedString("Post failed to upload",
                                                      comment: "Title of notification displayed when a post has failed to upload.")
    static let changesWillBeUploaded = NSLocalizedString("Changes will be uploaded next time your device is online",
                                                         comment: "Text displayed in notice after the app fails to upload a post.")
    static let willAttemptToPublishLater = NSLocalizedString("Post couldn't be published. We'll try again later",
                                                       comment: "Text displayed in notice after the app fails to upload a post, it will attempt to upload it later.")
    static let willNotAttemptToPublishLater = NSLocalizedString("Couldn't perform operation. Post not published",
                                                        comment: "Text displayed in notice after the app fails to upload a post, not new attempt will be made.")
    static let willAttemptToSubmitLater = NSLocalizedString("Post couldn't be submitted. We'll try again later",
                                                       comment: "Text displayed in notice after the app fails to upload a post, it will attempt to upload it later.")
    static let willNotAttemptToSubmitLater = NSLocalizedString("Couldn't perform operation",
                                                        comment: "Text displayed in notice after the app fails to upload a post, not new attempt will be made.")

    static func willAttemptToAutoUpload(for postStatus: BasePost.Status?) -> String {
        return postStatus == .publish ? PostAutoUploadMessages.willAttemptToPublishLater : PostAutoUploadMessages.willAttemptToSubmitLater
    }

    static func willNotAttemptToAutoUpload(for postStatus: BasePost.Status?) -> String {
        return postStatus == .publish ? PostAutoUploadMessages.willNotAttemptToPublishLater : PostAutoUploadMessages.willNotAttemptToSubmitLater
    }

    static func attemptFailures(for post: AbstractPost,
                                withState state: PostAutoUploadInteractor.AutoUploadAttemptState) -> String? {
        switch state {
        case .attempted:
            return PostAutoUploadMessages.willAttemptToAutoUpload(for: post.status)
        case .reachedLimit:
            return PostAutoUploadMessages.willNotAttemptToAutoUpload(for: post.status)
        default:
            return nil
        }
    }
}
