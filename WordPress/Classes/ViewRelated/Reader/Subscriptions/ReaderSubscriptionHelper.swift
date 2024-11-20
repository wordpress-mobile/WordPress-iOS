import SwiftUI

struct ReaderSubscriptionHelper {
    let contextManager: CoreDataStackSwift = ContextManager.shared

    // MARK: Subscribe

    func toggleSiteSubscription(forPost post: ReaderPost) {
        ReaderFollowAction().execute(with: post, context: ContextManager.shared.mainContext, completion: { isFollowing in
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            ReaderHelpers.dispatchToggleFollowSiteMessage(post: post, follow: isFollowing, success: true)
        }, failure: { _, _ in
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        })
    }

    // MARK: Subscribe (RSS)

    @MainActor
    func followSite(withURL siteURL: String) async throws {
        guard let url = makeURL(fromUserInput: siteURL) else {
            throw ReaderFollowSiteError.invalidURL
        }

        let generator = UINotificationFeedbackGenerator()
        generator.prepare()

        try await withUnsafeThrowingContinuation { continuation in
            let service = ReaderSiteService(coreDataStack: contextManager)
            service.followSite(by: url, success: {
                ReaderTopicService(coreDataStack: contextManager)
                    .fetchAllFollowedSites(success: {}, failure: { _ in })
                generator.notificationOccurred(.success)
                continuation.resume(returning: ())
            }, failure: { error in
                DDLogError("Could not follow site: \(String(describing: error))")
                generator.notificationOccurred(.error)
                continuation.resume(throwing: error ?? URLError(.unknown))
            })
        }
    }

    // MARK: Subscribe/Unsubscribe (ReaderSiteTopic)

    func toggleFollowingForSite(_ topic: ReaderSiteTopic, completion: ((Bool) -> Void)? = nil) {
        if topic.following {
            ReaderSubscribingNotificationAction().execute(for: topic.siteID, context: contextManager.mainContext, subscribe: false)
        }

        let service = ReaderTopicService(coreDataStack: contextManager)
        service.toggleFollowing(forSite: topic, success: { follow in
            ReaderHelpers.dispatchToggleFollowSiteMessage(site: topic, follow: follow, success: true)
            completion?(true)
        }, failure: { (follow, error) in
            ReaderHelpers.dispatchToggleFollowSiteMessage(site: topic, follow: follow, success: false)
            completion?(false)
        })
    }

    @MainActor
    func unfollow(_ site: ReaderSiteTopic) {
        NotificationCenter.default.post(name: .ReaderTopicUnfollowed, object: nil, userInfo: [ReaderNotificationKeys.topic: site])
        let service = ReaderTopicService(coreDataStack: contextManager)
        service.toggleFollowing(forSite: site, success: { _ in
            // Do nothing
        }, failure: { _, error in
            DDLogError("Could not unfollow site: \(String(describing: error))")
            let title = NSLocalizedString("reader.notice.blog.unsubscribed.error", value: "Could not unsubscribe from blog", comment: "Title of a prompt.")
            Notice(title: title, message: error?.localizedDescription, feedbackType: .error).post()
        })
    }
}

enum ReaderFollowSiteError: LocalizedError {
    case invalidURL

    var errorDescription: String? {
        switch self {
        case .invalidURL: NSLocalizedString("reader.subscription.invalidURLError", value: "Please enter a valid URL", comment: "Short error message")
        }
    }
}

private func makeURL(fromUserInput string: String) -> URL? {
    var string = string.trimmingCharacters(in: .whitespacesAndNewlines)
    if string.contains(" ") {
        return nil
    }
    // if the string does not have either a dot or protocol its not a URL
    if !string.contains(".") && !string.contains("://") {
        return nil
    }
    if !string.contains("://") {
        string = "http://\(string)"
    }
    if let url = URL(string: string), url.host != nil {
        return url
    }
    return nil
}

enum ReaderSubscriptionNotificationsStatus {
    /// Receives both posts and notifications
    case all
    /// Receives some notifications
    case personalized
    /// Receives none
    case none

    init?(site: ReaderSiteTopic) {
        guard !site.isExternal else {
            return nil
        }
        let posts = site.postSubscription
        let emails = site.emailSubscription

        let sendPosts = (posts?.sendPosts ?? false) || (emails?.sendPosts ?? false)
        let sendComments = emails?.sendComments ?? false
        if sendPosts && sendComments {
            self = .all
        } else if sendPosts || sendComments {
            self = .personalized
        } else {
            self = .none
        }
    }
}
