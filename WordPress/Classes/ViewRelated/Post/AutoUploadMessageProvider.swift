import Foundation

protocol AutoUploadMessageProvider {

    // MARK: - Cancelling

    static var changesWillNotBePublished: String { get }
    static var changesWillNotBeSaved: String { get }
    static var changesWillNotBeScheduled: String { get }
    static var changesWillNotBeSubmitted: String { get }

    // MARK: - Online

    static var onlineUploadFailure: String { get }

    // MARK: - Offline: First Try

    static var offlineDraftFailureFirstTry: String { get }
    static var offlinePrivateFailureFirstTry: String { get }
    static var offlinePublishFailureFirstTry: String { get }
    static var offlineScheduledFailureFirstTry: String { get }
    static var offlineSubmitFailureFirstTry: String { get }

    // MARK: - Offline: Retry

    static var onlineDefaultFailureRetry: String { get }
    static var onlinePublishFailureRetry: String { get }
    static var onlinePrivateFailureRetry: String { get }
    static var onlineScheduleFailureRetry: String { get }
    static var onlineSubmitFailureRetry: String { get }

    // MARK: - Offline: No Retry

    static var onlineDefaultFailureWithoutRetry: String { get }
    static var onlinePublishFailureWithoutRetry: String { get }
    static var onlinePrivateFailureWithoutRetry: String { get }
    static var onlineScheduleFailureWithoutRetry: String { get }
    static var onlineSubmitFailureWithoutRetry: String { get }

    // MARK: - Failed Media

    static var failedMedia: String { get }
    static var failedMediaForPublish: String { get }
    static var failedMediaForPrivate: String { get }
    static var failedMediaForScheduled: String { get }
    static var failedMediaForPending: String { get }
}
