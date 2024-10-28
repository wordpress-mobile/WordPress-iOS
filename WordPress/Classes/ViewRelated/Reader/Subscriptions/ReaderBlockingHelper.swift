import Foundation

struct ReaderBlockingHelper {
    func blockSite(forPost post: ReaderPost, context: NSManagedObjectContext = ContextManager.shared.mainContext) {
        postSiteBlockingWillBeginNotification(post)

        ReaderBlockSiteAction(asBlocked: true).execute(with: post, context: context, completion: {
            ReaderHelpers.dispatchSiteBlockedMessage(post: post, success: true)
            postSiteBlockingDidFinish(post)
        }, failure: { error in
            ReaderHelpers.dispatchSiteBlockedMessage(post: post, success: false)
            postSiteBlockingDidFail(post, error: error)
        })
    }

    func blockUser(forPost post: ReaderPost, context: NSManagedObjectContext = ContextManager.shared.mainContext) {
        postUserBlockingWillBeginNotification(post)
        ReaderBlockUserAction(context: context).execute(with: post, blocked: true) { result in
            switch result {
            case .success:
                ReaderHelpers.dispatchUserBlockedMessage(post: post, success: true)
            case .failure:
                ReaderHelpers.dispatchUserBlockedMessage(post: post, success: false)
            }
            postUserBlockingDidFinishNotification(post, result: result)
        }
    }

    // MARK: Helpers

    private func postSiteBlockingWillBeginNotification(_ post: ReaderPost) {
        NotificationCenter.default.post(name: .ReaderSiteBlockingWillBegin, object: nil, userInfo: [ReaderNotificationKeys.post: post])
    }

    /// Notify Reader Cards Stream so the post card is updated.
    private func postSiteBlockingDidFinish(_ post: ReaderPost) {
        NotificationCenter.default.post(name: .ReaderSiteBlocked, object: nil, userInfo: [ReaderNotificationKeys.post: post])
    }

    private func postSiteBlockingDidFail(_ post: ReaderPost, error: Error?) {
        var userInfo: [String: Any] = [ReaderNotificationKeys.post: post]
        if let error {
            userInfo[ReaderNotificationKeys.error] = error
        }
        NotificationCenter.default.post(name: .ReaderSiteBlockingFailed, object: nil, userInfo: userInfo)
    }

    private func postUserBlockingWillBeginNotification(_ post: ReaderPost) {
        NotificationCenter.default.post(name: .ReaderUserBlockingWillBegin, object: nil, userInfo: [ReaderNotificationKeys.post: post])
    }

    private func postUserBlockingDidFinishNotification(_ post: ReaderPost, result: Result<Void, Error>) {
        let center = NotificationCenter.default
        let userInfo: [String: Any] = [ReaderNotificationKeys.post: post, ReaderNotificationKeys.result: result]
        center.post(name: .ReaderUserBlockingDidEnd, object: nil, userInfo: userInfo)
    }
}
