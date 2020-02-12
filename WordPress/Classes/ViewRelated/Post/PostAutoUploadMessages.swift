import Foundation

class PostAutoUploadMessages {
    let post: AbstractPost
    let messageProvider: AutoUploadMessageProvider.Type

    init(for post: AbstractPost) {
        self.post = post

        if post is Page {
            messageProvider = PageAutoUploadMessageProvider.self
        } else {
            messageProvider = PostAutoUploadMessageProvider.self
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

    func onlineFailedUploadMessage() -> String {
        return messageProvider.onlineUploadFailure
    }

    func offlineFailedUploadMessage(withState state: PostAutoUploadInteractor.AutoUploadAttemptState) -> String {
        switch state {
        case .notAttempted:
            return offlineFailedUploadMessageFirstTry(postStatus: post.status)
        case .attempted:
            return offlineFailedUploadMessageWithRetry(for: post.status)
        case .reachedLimit:
            return post.hasFailedMedia ? failedMediaUploadMessage(for: post.status) : offlineFailedUploadMessageWithoutRetry(for: post.status)
        }
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
            return messageProvider.onlineSubmitFailureRetry
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
