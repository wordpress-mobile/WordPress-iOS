import Foundation

class PostAutoUploadMessageProvider: AutoUploadMessageProvider {

    // MARK: - Cancelling

    let changesWillNotBePublished = NSLocalizedString("We won't publish these changes.",
                                                      comment: "Title for notice displayed on canceling auto-upload published post")
    let changesWillNotBeSaved = NSLocalizedString("We won't save the latest changes to your draft.",
                                                  comment: "Title for notice displayed on canceling auto-upload of a draft post")
    let changesWillNotBeScheduled = NSLocalizedString("We won't schedule these changes.",
                                                      comment: "Title for notice displayed on canceling auto-upload of a scheduled post")
    let changesWillNotBeSubmitted = NSLocalizedString("We won't submit these changes for review.",
                                                      comment: "Title for notice displayed on canceling auto-upload pending post")

    // MARK: - Online

    private static let defaultOnlineUploadFailure = NSLocalizedString("Post failed to upload",
                                                                      comment: "Title of notification displayed when a post has failed to upload.")

    /// This can be overridden.
    ///
    let onlineUploadFailure: String

    // MARK: - Offline: First Try

    let offlineDraftFailureFirstTry = NSLocalizedString("We'll save your draft when your device is back online.",
                                                        comment: "Text displayed in notice after the app fails to upload a draft.")
    let offlinePrivateFailureFirstTry = NSLocalizedString("We'll publish your private post when your device is back online.",
                                                          comment: "Text displayed in notice after the app fails to upload a private post.")
    let offlinePublishFailureFirstTry = NSLocalizedString("We'll publish the post when your device is back online.",
                                                          comment: "Text displayed in notice after a post if published while offline.")
    let offlineScheduledFailureFirstTry = NSLocalizedString("We'll schedule your post when your device is back online.",
                                                            comment: "Text displayed after the app fails to upload a scheduled post.")
    let offlineSubmitFailureFirstTry = NSLocalizedString("We'll submit your post for review when your device is back online.",
                                                         comment: "Text displayed in notice after the app fails to upload a post, it will attempt to upload it later.")

    // MARK: - Offline: Retry

    let onlineDefaultFailureRetry = NSLocalizedString("We couldn't complete this action, but we'll try again later.",
                                                      comment: "Text displayed after the app fails to upload a post, it will attempt to upload it later.")
    let onlinePublishFailureRetry = NSLocalizedString("We couldn't publish this post, but we'll try again later.",
                                                      comment: "Text displayed in notice after the app fails to upload a post, it will attempt to upload it later.")
    let onlinePrivateFailureRetry = NSLocalizedString("We couldn't publish this private post, but we'll try again later.",
                                                      comment: "Text displayed after the app fails to upload a private post, it will attempt to upload it later.")
    let onlineScheduleFailureRetry = NSLocalizedString("We couldn't schedule this post, but we'll try again later.",
                                                       comment: "Text displayed after the app fails to upload a scheduled post, it will attempt to upload it later.")
    let onlineSubmitFailureRetry = NSLocalizedString("We couldn't submit this post for review, but we'll try again later.",
                                                     comment: "Text displayed in notice after the app fails to upload a post, it will attempt to upload it later.")

    // MARK: - Offline: No Retry

    let onlineDefaultFailureWithoutRetry = NSLocalizedString("We couldn't complete this action.",
                                                             comment: "Text displayed after the app fails to upload a post, no new attempt will be made.")
    let onlinePublishFailureWithoutRetry = NSLocalizedString("We couldn't complete this action, and didn't publish this post.",
                                                             comment: "Text displayed in notice after the app fails to upload a post, not new attempt will be made.")
    let onlinePrivateFailureWithoutRetry = NSLocalizedString("We couldn't complete this action, and didn't publish this private post.",
                                                             comment: "Text displayed after the app fails to upload a private post, no new attempt will be made.")
    let onlineScheduleFailureWithoutRetry = NSLocalizedString("We couldn't complete this action, and didn't schedule this post.",
                                                              comment: "Text displayed after the app fails to upload a scheduled post, no new attempt will be made.")
    let onlineSubmitFailureWithoutRetry = NSLocalizedString("We couldn't complete this action, and didn't submit this post for review.",
                                                            comment: "Text displayed in notice after the app fails to upload a post, not new attempt will be made.")

    // MARK: - Failed Media

    let failedMedia = NSLocalizedString("We couldn't upload this media.",
                                        comment: "Text displayed if a media couldnt be uploaded.")
    let failedMediaForPublish = NSLocalizedString("We couldn't upload this media, and didn't publish the post.",
                                                  comment: "Text displayed if a media couldn't be uploaded for a published post.")
    let failedMediaForPrivate = NSLocalizedString("We couldn't upload this media, and didn't publish this private post.",
                                                  comment: "Text displayed if a media couldn't be uploaded for a private post.")
    let failedMediaForScheduled = NSLocalizedString("We couldn't upload this media, and didn't schedule this post.",
                                                    comment: "Text displayed if a media couldn't be uploaded for a scheduled post.")
    let failedMediaForPending = NSLocalizedString("We couldn't upload this media, and didn't submit this post for review.",
                                                  comment: "Text displayed if a media couldn't be uploaded for a pending post.")

    /// Default initializer.
    ///
    init(onlineUploadFailure: String = PostAutoUploadMessageProvider.defaultOnlineUploadFailure) {
        self.onlineUploadFailure = onlineUploadFailure
    }
}
