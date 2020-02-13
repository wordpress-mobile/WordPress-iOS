import Foundation

class PageAutoUploadMessageProvider: AutoUploadMessageProvider {

    // MARK: - Cancelling

    static let changesWillNotBePublished = NSLocalizedString("We won't publish these changes.",
                                                             comment: "Title for notice displayed on canceling auto-upload published page")
    static let changesWillNotBeSaved = NSLocalizedString("We won't save the latest changes to your draft.",
                                                         comment: "Title for notice displayed on canceling auto-upload of a draft page")
    static let changesWillNotBeScheduled = NSLocalizedString("We won't schedule these changes.",
                                                             comment: "Title for notice displayed on canceling auto-upload of a scheduled page")
    static let changesWillNotBeSubmitted = NSLocalizedString("We won't submit these changes for review.",
                                                             comment: "Title for notice displayed on canceling auto-upload pending page")

    // MARK: - Online

    static let onlineUploadFailure = NSLocalizedString("Page failed to upload",
                                                       comment: "Title of notification displayed when a page has failed to upload.")

    // MARK: - Offline: First Try

    static let offlineDraftFailureFirstTry = NSLocalizedString("We'll save your draft when your device is back online.",
                                                               comment: "Text displayed in notice after the app fails to upload a draft.")
    static let offlinePrivateFailureFirstTry = NSLocalizedString("We'll publish your private page when your device is back online.",
                                                                 comment: "Text displayed in notice after the app fails to upload a private page.")
    static let offlinePublishFailureFirstTry = NSLocalizedString("We'll publish the page when your device is back online.",
                                                                 comment: "Text displayed in notice after a page if published while offline.")
    static let offlineScheduledFailureFirstTry = NSLocalizedString("We'll schedule your page when your device is back online.",
                                                                   comment: "Text displayed after the app fails to upload a scheduled page.")
    static let offlineSubmitFailureFirstTry = NSLocalizedString("We'll submit your page for review when your device is back online.",
                                                                comment: "Text displayed in notice after the app fails to upload a page], it will attempt to upload it later.")


    // MARK: - Offline: Retry

    static let onlineDefaultFailureRetry = NSLocalizedString("We couldn't complete this action, but we'll try again later.",
                                                             comment: "Text displayed after the app fails to upload a page, it will attempt to upload it later.")
    static let onlinePublishFailureRetry = NSLocalizedString("We couldn't publish this page, but we'll try again later.",
                                                             comment: "Text displayed in notice after the app fails to upload a page, it will attempt to upload it later.")
    static let onlinePrivateFailureRetry = NSLocalizedString("We couldn't publish this private page, but we'll try again later.",
                                                             comment: "Text displayed after the app fails to upload a private page, it will attempt to upload it later.")
    static let onlineScheduleFailureRetry = NSLocalizedString("We couldn't schedule this page, but we'll try again later.",
                                                              comment: "Text displayed after the app fails to upload a scheduled page, it will attempt to upload it later.")
    static let onlineSubmitFailureRetry = NSLocalizedString("We couldn't submit this page for review, but we'll try again later.",
                                                            comment: "Text displayed in notice after the app fails to upload a page, it will attempt to upload it later.")

    // MARK: - Offline: No Retry

    static let onlineDefaultFailureWithoutRetry = NSLocalizedString("We couldn't complete this action.",
                                                                    comment: "Text displayed after the app fails to upload a page, no new attempt will be made.")
    static let onlinePublishFailureWithoutRetry = NSLocalizedString("We couldn't complete this action, and didn't publish this page.",
                                                                    comment: "Text displayed in notice after the app fails to upload a page, not new attempt will be made.")
    static let onlinePrivateFailureWithoutRetry = NSLocalizedString("We couldn't complete this action, and didn't publish this private page.",
                                                                    comment: "Text displayed after the app fails to upload a private page, no new attempt will be made.")
    static let onlineScheduleFailureWithoutRetry = NSLocalizedString("We couldn't complete this action, and didn't schedule this page.",
                                                                     comment: "Text displayed after the app fails to upload a scheduled page, no new attempt will be made.")
    static let onlineSubmitFailureWithoutRetry = NSLocalizedString("We couldn't complete this action, and didn't submit this page for review.",
                                                                   comment: "Text displayed in notice after the app fails to upload a page, not new attempt will be made.")

    // MARK: - Failed Media

    static let failedMedia = NSLocalizedString("We couldn't upload this media.",
                                               comment: "Text displayed if a media couldnt be uploaded.")
    static let failedMediaForPublish = NSLocalizedString("We couldn't upload this media, and didn't publish the page.",
                                                         comment: "Text displayed if a media couldn't be uploaded for a published page.")
    static let failedMediaForPrivate = NSLocalizedString("We couldn't upload this media, and didn't publish this private page.",
                                                         comment: "Text displayed if a media couldn't be uploaded for a private page.")
    static let failedMediaForScheduled = NSLocalizedString("We couldn't upload this media, and didn't schedule this page.",
                                                           comment: "Text displayed if a media couldn't be uploaded for a scheduled page.")
    static let failedMediaForPending = NSLocalizedString("We couldn't upload this media, and didn't submit this page for review.",
                                                         comment: "Text displayed if a media couldn't be uploaded for a pending page.")
}
