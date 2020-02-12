import Foundation

class PageAutoUploadMessageProvider: AutoUploadMessageProvider {

    // MARK: - Cancelling

    let changesWillNotBePublished = NSLocalizedString("We won't publish these changes.",
                                                      comment: "Title for notice displayed on canceling auto-upload published page")
    let changesWillNotBeSaved = NSLocalizedString("We won't save the latest changes to your draft.",
                                                  comment: "Title for notice displayed on canceling auto-upload of a draft page")
    let changesWillNotBeScheduled = NSLocalizedString("We won't schedule these changes.",
                                                      comment: "Title for notice displayed on canceling auto-upload of a scheduled page")
    let changesWillNotBeSubmitted = NSLocalizedString("We won't submit these changes for review.",
                                                      comment: "Title for notice displayed on canceling auto-upload pending page")

    // MARK: - Online

    let onlineUploadFailure = NSLocalizedString("Page failed to upload",
                                                comment: "Title of notification displayed when a page has failed to upload.")

    // MARK: - Offline: First Try

    let offlineDraftFailureFirstTry = NSLocalizedString("We'll save your draft when your device is back online.",
                                                        comment: "Text displayed in notice after the app fails to upload a draft.")
    let offlinePrivateFailureFirstTry = NSLocalizedString("We'll publish your private page when your device is back online.",
                                                          comment: "Text displayed in notice after the app fails to upload a private page.")
    let offlinePublishFailureFirstTry = NSLocalizedString("We'll publish the page when your device is back online.",
                                                          comment: "Text displayed in notice after a page if published while offline.")
    let offlineScheduledFailureFirstTry = NSLocalizedString("We'll schedule your page when your device is back online.",
                                                            comment: "Text displayed after the app fails to upload a scheduled page.")


    // MARK: - Offline: Retry

    let onlineDefaultFailureRetry = NSLocalizedString("We couldn't complete this action, but we'll try again later.",
                                                      comment: "Text displayed after the app fails to upload a page, it will attempt to upload it later.")
    let onlinePublishFailureRetry = NSLocalizedString("We couldn't publish this page, but we'll try again later.",
                                                      comment: "Text displayed in notice after the app fails to upload a page, it will attempt to upload it later.")
    let onlinePrivateFailureRetry = NSLocalizedString("We couldn't publish this private page, but we'll try again later.",
                                                      comment: "Text displayed after the app fails to upload a private page, it will attempt to upload it later.")
    let onlineScheduleFailureRetry = NSLocalizedString("We couldn't schedule this page, but we'll try again later.",
                                                       comment: "Text displayed after the app fails to upload a scheduled page, it will attempt to upload it later.")
    let onlineSubmitFailureRetry = NSLocalizedString("We couldn't submit this page for review, but we'll try again later.",
                                                     comment: "Text displayed in notice after the app fails to upload a page, it will attempt to upload it later.")
    let offlineSubmitFailureFirstTry = NSLocalizedString("We'll submit your page for review when your device is back online.",
                                                         comment: "Text displayed in notice after the app fails to upload a page], it will attempt to upload it later.")

    // MARK: - Offline: No Retry

    let onlineDefaultFailureWithoutRetry = NSLocalizedString("We couldn't complete this action.",
                                                             comment: "Text displayed after the app fails to upload a page, no new attempt will be made.")
    let onlinePublishFailureWithoutRetry = NSLocalizedString("We couldn't complete this action, and didn't publish this page.",
                                                             comment: "Text displayed in notice after the app fails to upload a page, not new attempt will be made.")
    let onlinePrivateFailureWithoutRetry = NSLocalizedString("We couldn't complete this action, and didn't publish this private page.",
                                                             comment: "Text displayed after the app fails to upload a private page, no new attempt will be made.")
    let onlineScheduleFailureWithoutRetry = NSLocalizedString("We couldn't complete this action, and didn't schedule this page.",
                                                              comment: "Text displayed after the app fails to upload a scheduled page, no new attempt will be made.")
    let onlineSubmitFailureWithoutRetry = NSLocalizedString("We couldn't complete this action, and didn't submit this page for review.",
                                                            comment: "Text displayed in notice after the app fails to upload a page, not new attempt will be made.")

    // MARK: - Failed Media

    let failedMedia = NSLocalizedString("We couldn't upload this media.",
                                        comment: "Text displayed if a media couldnt be uploaded.")
    let failedMediaForPublish = NSLocalizedString("We couldn't upload this media, and didn't publish the page.",
                                                  comment: "Text displayed if a media couldn't be uploaded for a published page.")
    let failedMediaForPrivate = NSLocalizedString("We couldn't upload this media, and didn't publish this private page.",
                                                  comment: "Text displayed if a media couldn't be uploaded for a private page.")
    let failedMediaForScheduled = NSLocalizedString("We couldn't upload this media, and didn't schedule this page.",
                                                    comment: "Text displayed if a media couldn't be uploaded for a scheduled page.")
    let failedMediaForPending = NSLocalizedString("We couldn't upload this media, and didn't submit this page for review.",
                                                  comment: "Text displayed if a media couldn't be uploaded for a pending page.")
}
