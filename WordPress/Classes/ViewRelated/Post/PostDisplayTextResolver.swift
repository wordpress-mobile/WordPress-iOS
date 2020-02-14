import Foundation

class PostDisplayTextResolver {
    let post: AbstractPost
    let textProvider: AbstractPostDisplayTextProvider.Type

    // MARK: - Initialization

    init(for post: AbstractPost) {
        self.post = post

        if post is Page {
            self.textProvider = PageDisplayTextProvider.self
        } else {
            self.textProvider = PostDisplayTextProvider.self
        }
    }

    // MARK: - Titles

    func title() -> String {
        let status = post.status ?? .publish

        switch status {
        case .draft:
            return textProvider.draftUploadedTitle
        case .scheduled:
            return textProvider.scheduledTitle
        case .pending:
            return textProvider.pendingTitle
        default:
            return textProvider.publishedTitle
        }
    }

    // MARK: - Cancelling

    func cancelMessage() -> String {
        switch post.status {
        case .publish:
            return textProvider.changesWillNotBePublished
        case .publishPrivate:
            return textProvider.changesWillNotBePublished
        case .scheduled:
            return textProvider.changesWillNotBeScheduled
        case .draft:
            return textProvider.changesWillNotBeSaved
        default:
            return textProvider.changesWillNotBeSubmitted
        }
    }

    // MARK: - Failure Messages

    func failedUploadMessage(
        isInternetReachable: Bool,
        autoUploadState state: PostAutoUploadInteractor.AutoUploadAttemptState,
        autoUploadAction: PostAutoUploadInteractor.AutoUploadAction,
        onlineFailedUploadMessageOverride: String? = nil) -> String {

        guard !isInternetReachable else {
            return onlineFailedUploadMessage(override: onlineFailedUploadMessageOverride)
        }

        switch state {
        case .notAttempted:
            guard autoUploadAction == .upload else {
                return onlineFailedUploadMessage(override: onlineFailedUploadMessageOverride)
            }

            return offlineFailedUploadMessageFirstTry(postStatus: post.status)
        case .attempted:
            guard autoUploadAction == .upload else {
                return onlineFailedUploadMessage(override: onlineFailedUploadMessageOverride)
            }

            return offlineFailedUploadMessageWithRetry(for: post.status)
        case .reachedLimit:
            return post.hasFailedMedia ? failedMediaUploadMessage(for: post.status) : offlineFailedUploadMessageWithoutRetry(for: post.status)
        }
    }

    private func onlineFailedUploadMessage(override: String?) -> String {
        if let override = override {
            return override
        }

        return textProvider.onlineUploadFailure
    }

    private func offlineFailedUploadMessageFirstTry(
        postStatus: BasePost.Status?) -> String {

        switch postStatus {
        case .draft:
            return textProvider.offlineDraftFailureFirstTry
        case .publishPrivate:
            return textProvider.offlinePrivateFailureFirstTry
        case .scheduled:
            return textProvider.offlineScheduledFailureFirstTry
        case .publish:
            return textProvider.offlinePublishFailureFirstTry
        default:
            return textProvider.offlineSubmitFailureFirstTry
        }
    }

    private func offlineFailedUploadMessageWithRetry(
        for postStatus: BasePost.Status?) -> String {

        switch postStatus {
        case .publish:
            return textProvider.onlinePublishFailureRetry
        case .publishPrivate:
            return textProvider.onlinePrivateFailureRetry
        case .scheduled:
            return textProvider.onlineScheduleFailureRetry
        case .pending:
            return textProvider.onlineSubmitFailureRetry
        default:
            return textProvider.onlineDefaultFailureRetry
        }
    }

    private func offlineFailedUploadMessageWithoutRetry(for postStatus: BasePost.Status?) -> String {
        switch postStatus {
        case .publish:
            return textProvider.onlinePublishFailureWithoutRetry
        case .publishPrivate:
            return textProvider.onlinePrivateFailureWithoutRetry
        case .scheduled:
            return textProvider.onlineScheduleFailureWithoutRetry
        case .pending:
            return textProvider.onlineSubmitFailureWithoutRetry
        default:
            return textProvider.onlineDefaultFailureWithoutRetry
        }
    }

    // MARK: - Failed Media

    func failedMediaUploadMessage(for postStatus: BasePost.Status?) -> String {
        switch postStatus {
        case .publish:
            return textProvider.failedMediaForPublish
        case .publishPrivate:
            return textProvider.failedMediaForPrivate
        case .scheduled:
            return textProvider.failedMediaForScheduled
        case .pending:
            return textProvider.failedMediaForPending
        default:
            return textProvider.failedMedia
        }
    }
}
