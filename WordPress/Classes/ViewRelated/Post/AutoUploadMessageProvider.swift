import Foundation

protocol AutoUploadMessageProvider {

    // MARK: - Cancelling

    var changesWillNotBePublished: String { get }
    var changesWillNotBeSaved: String { get }
    var changesWillNotBeScheduled: String { get }
    var changesWillNotBeSubmitted: String { get }

    // MARK: - Online

    var onlineUploadFailure: String { get }

    // MARK: - Offline: First Try

    var offlineDraftFailureFirstTry: String { get }
    var offlinePrivateFailureFirstTry: String { get }
    var offlinePublishFailureFirstTry: String { get }
    var offlineScheduledFailureFirstTry: String { get }
    var offlineSubmitFailureFirstTry: String { get }

    // MARK: - Offline: Retry

    var onlineDefaultFailureRetry: String { get }
    var onlinePublishFailureRetry: String { get }
    var onlinePrivateFailureRetry: String { get }
    var onlineScheduleFailureRetry: String { get }
    var onlineSubmitFailureRetry: String { get }

    // MARK: - Offline: No Retry

    var onlineDefaultFailureWithoutRetry: String { get }
    var onlinePublishFailureWithoutRetry: String { get }
    var onlinePrivateFailureWithoutRetry: String { get }
    var onlineScheduleFailureWithoutRetry: String { get }
    var onlineSubmitFailureWithoutRetry: String { get }

    // MARK: - Failed Media

    var failedMedia: String { get }
    var failedMediaForPublish: String { get }
    var failedMediaForPrivate: String { get }
    var failedMediaForScheduled: String { get }
    var failedMediaForPending: String { get }
}
