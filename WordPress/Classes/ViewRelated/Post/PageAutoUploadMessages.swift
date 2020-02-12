import Foundation

enum PageAutoUploadMessages {
    static let pageWillBePublished = NSLocalizedString("We'll publish the page when your device is back online.",
                                                       comment: "Text displayed in notice after a page if published while offline.")
    static let draftWillBeUploaded = NSLocalizedString("We'll save your draft when your device is back online.",
                                                       comment: "Text displayed in notice after the app fails to upload a draft.")
    static let pageFailedToUpload = NSLocalizedString("Page failed to upload",
                                                      comment: "Title of notification displayed when a page has failed to upload.")
    static let willAttemptToPublishLater = NSLocalizedString("We couldn't publish this page, but we'll try again later.",
                                                       comment: "Text displayed in notice after the app fails to upload a page, it will attempt to upload it later.")
    static let willNotAttemptToPublishLater = NSLocalizedString("We couldn't complete this action, and didn't publish this page.",
                                                        comment: "Text displayed in notice after the app fails to upload a page, not new attempt will be made.")
    static let willSubmitLater = NSLocalizedString("We'll submit your page for review when your device is back online.",
                                                        comment: "Text displayed in notice after the app fails to upload a page, it will attempt to upload it later.")
    static let willAttemptToSubmitLater = NSLocalizedString("We couldn't submit this page for review, but we'll try again later.",
                                                       comment: "Text displayed in notice after the app fails to upload a page, it will attempt to upload it later.")
    static let willAttemptLater = NSLocalizedString("We couldn't complete this action, but we'll try again later.",
                                                        comment: "Text displayed after the app fails to upload a page, it will attempt to upload it later.")
    static let willNotAttemptToSubmitLater = NSLocalizedString("We couldn't complete this action, and didn't submit this page for review.",
                                                        comment: "Text displayed in notice after the app fails to upload a page, not new attempt will be made.")
    static let privateWillBeUploaded = NSLocalizedString("We'll publish your private page when your device is back online.",
                                                       comment: "Text displayed in notice after the app fails to upload a draft.")
    static let willAttemptToPublishPrivateLater = NSLocalizedString("We couldn't publish this private page, but we'll try again later.",
                                                        comment: "Text displayed after the app fails to upload a private page, it will attempt to upload it later.")
    static let willNotAttemptToPublishPrivateLater = NSLocalizedString("We couldn't complete this action, and didn't publish this private page.",
                                                        comment: "Text displayed after the app fails to upload a private page, no new attempt will be made.")
    static let scheduledWillBeUploaded = NSLocalizedString("We'll schedule your page when your device is back online.",
                                                       comment: "Text displayed after the app fails to upload a scheduled page.")
    static let willAttemptToScheduleLater = NSLocalizedString("We couldn't schedule this page, but we'll try again later.",
                                                        comment: "Text displayed after the app fails to upload a scheduled page, it will attempt to upload it later.")
    static let willNotAttemptToScheduleLater = NSLocalizedString("We couldn't complete this action, and didn't schedule this page.",
                                                        comment: "Text displayed after the app fails to upload a scheduled page, no new attempt will be made.")
    static let willNotAttemptLater = NSLocalizedString("We couldn't complete this action.",
                                                        comment: "Text displayed after the app fails to upload a page, no new attempt will be made.")
    static let changesWillNotBePublished = NSLocalizedString("We won't publish these changes.",
                                                        comment: "Title for notice displayed on canceling auto-upload published page")
    static let changesWillNotBeSubmitted = NSLocalizedString("We won't submit these changes for review.",
                                                         comment: "Title for notice displayed on canceling auto-upload pending page")
    static let changesWillNotBeScheduled = NSLocalizedString("We won't schedule these changes.",
                                                         comment: "Title for notice displayed on canceling auto-upload of a scheduled page")
    static let changesWillNotBeSaved = NSLocalizedString("We won't save the latest changes to your draft.",
                                                         comment: "Title for notice displayed on canceling auto-upload of a draft page")
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

    static func cancelMessage(for pageStatus: BasePost.Status?) -> String {
        switch pageStatus {
        case .publish:
            return PageAutoUploadMessages.changesWillNotBePublished
        case .publishPrivate:
            return PageAutoUploadMessages.changesWillNotBePublished
        case .scheduled:
            return PageAutoUploadMessages.changesWillNotBeScheduled
        case .draft:
            return PageAutoUploadMessages.changesWillNotBeSaved
        default:
            return PageAutoUploadMessages.changesWillNotBeSubmitted
        }
    }

    static func attemptFailures(for page: Page,
                                withState state: PostAutoUploadInteractor.AutoUploadAttemptState) -> String? {
        switch state {
        case .attempted:
            return PageAutoUploadMessages.willAttemptToAutoUpload(for: page.status)
        case .reachedLimit:
            return page.hasFailedMedia ? PageAutoUploadMessages.failedMedia(for: page.status) : PageAutoUploadMessages.willNotAttemptToAutoUpload(for: page.status)
        default:
            return nil
        }
    }

    static func failedMedia(for pageStatus: BasePost.Status?) -> String {
        switch pageStatus {
        case .publish:
            return PageAutoUploadMessages.failedMediaForPublish
        case .publishPrivate:
            return PageAutoUploadMessages.failedMediaForPrivate
        case .scheduled:
            return PageAutoUploadMessages.failedMediaForScheduled
        case .pending:
            return PageAutoUploadMessages.failedMediaForPending
        default:
            return PageAutoUploadMessages.failedMedia
        }
    }

    private static func willAttemptToAutoUpload(for pageStatus: BasePost.Status?) -> String {
        switch pageStatus {
        case .publish:
            return PageAutoUploadMessages.willAttemptToPublishLater
        case .publishPrivate:
            return PageAutoUploadMessages.willAttemptToPublishPrivateLater
        case .scheduled:
            return PageAutoUploadMessages.willAttemptToScheduleLater
        case .pending:
            return PageAutoUploadMessages.willAttemptToSubmitLater
        default:
            return PageAutoUploadMessages.willAttemptLater
        }
    }

    private static func willNotAttemptToAutoUpload(for pageStatus: BasePost.Status?) -> String {
        switch pageStatus {
        case .publish:
            return PageAutoUploadMessages.willNotAttemptToPublishLater
        case .publishPrivate:
            return PageAutoUploadMessages.willNotAttemptToPublishPrivateLater
        case .scheduled:
            return PageAutoUploadMessages.willNotAttemptToScheduleLater
        case .pending:
            return PageAutoUploadMessages.willNotAttemptToSubmitLater
        default:
            return PageAutoUploadMessages.willNotAttemptLater
        }
    }
}
