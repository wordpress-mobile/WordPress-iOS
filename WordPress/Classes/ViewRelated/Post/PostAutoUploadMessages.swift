import Foundation

class PostAutoUploadMessages {
    let post: AbstractPost
    let messageProvider: AutoUploadMessageProvider.Type

    // MARK: - Overrideable Messages

    private let onlineFailedUploadMessageOverride: String?

    // MARK: - Initialization

    init(for post: AbstractPost, onlineFailedUploadMessage: String? = nil) {
        self.post = post

        onlineFailedUploadMessageOverride = onlineFailedUploadMessage

        if post is Page {
            self.messageProvider = PageAutoUploadMessageProvider.self
        } else {
            self.messageProvider = PostAutoUploadMessageProvider.self
        }
    }

    // MARK: - Cancelling

    func cancelMessage() -> String {
        switch post.status {
        case .publish:
            return messageProvider.changesWillNotBePublished
        case .publishPrivate:
            return messageProvider.changesWillNotBePublished
        case .scheduled:
            return messageProvider.changesWillNotBeScheduled
        case .draft:
            return messageProvider.changesWillNotBeSaved
        default:
            return messageProvider.changesWillNotBeSubmitted
        }
    }

    // MARK: - Failure Messages

    func failedUploadMessage(
        isInternetReachable: Bool,
        autoUploadState state: PostAutoUploadInteractor.AutoUploadAttemptState,
        autoUploadAction: PostAutoUploadInteractor.AutoUploadAction) -> String {

        guard !isInternetReachable else {
            return onlineFailedUploadMessage()
        }

        switch state {
        case .notAttempted:
            guard autoUploadAction == .upload else {
                return onlineFailedUploadMessage()
            }

            return offlineFailedUploadMessageFirstTry(postStatus: post.status)
        case .attempted:
            guard autoUploadAction == .upload else {
                return onlineFailedUploadMessage()
            }

            return offlineFailedUploadMessageWithRetry(for: post.status)
        case .reachedLimit:
            return post.hasFailedMedia ? failedMediaUploadMessage(for: post.status) : offlineFailedUploadMessageWithoutRetry(for: post.status)
        }
    }

    private func onlineFailedUploadMessage() -> String {
        if let onlineFailedUploadMessage = onlineFailedUploadMessageOverride {
            return onlineFailedUploadMessage
        }

        return messageProvider.onlineUploadFailure
    }

    private func offlineFailedUploadMessageFirstTry(
        postStatus: BasePost.Status?) -> String {

        switch postStatus {
        case .draft:
            return messageProvider.offlineDraftFailureFirstTry
        case .publishPrivate:
            return messageProvider.offlinePrivateFailureFirstTry
        case .scheduled:
            return messageProvider.offlineScheduledFailureFirstTry
        case .publish:
            return messageProvider.offlinePublishFailureFirstTry
        default:
            return messageProvider.offlineSubmitFailureFirstTry
        }
    }

    private func offlineFailedUploadMessageWithRetry(
        for postStatus: BasePost.Status?) -> String {

        switch postStatus {
        case .publish:
            return messageProvider.onlinePublishFailureRetry
        case .publishPrivate:
            return messageProvider.onlinePrivateFailureRetry
        case .scheduled:
            return messageProvider.onlineScheduleFailureRetry
        case .pending:
            return messageProvider.onlineSubmitFailureRetry
        default:
            return messageProvider.onlineDefaultFailureRetry
        }
    }

    private func offlineFailedUploadMessageWithoutRetry(for postStatus: BasePost.Status?) -> String {
        switch postStatus {
        case .publish:
            return messageProvider.onlinePublishFailureWithoutRetry
        case .publishPrivate:
            return messageProvider.onlinePrivateFailureWithoutRetry
        case .scheduled:
            return messageProvider.onlineScheduleFailureWithoutRetry
        case .pending:
            return messageProvider.onlineSubmitFailureWithoutRetry
        default:
            return messageProvider.onlineDefaultFailureWithoutRetry
        }
    }

    // MARK: - Failed Media

    func failedMediaUploadMessage(for postStatus: BasePost.Status?) -> String {
        switch postStatus {
        case .publish:
            return messageProvider.failedMediaForPublish
        case .publishPrivate:
            return messageProvider.failedMediaForPrivate
        case .scheduled:
            return messageProvider.failedMediaForScheduled
        case .pending:
            return messageProvider.failedMediaForPending
        default:
            return messageProvider.failedMedia
        }
    }
}
