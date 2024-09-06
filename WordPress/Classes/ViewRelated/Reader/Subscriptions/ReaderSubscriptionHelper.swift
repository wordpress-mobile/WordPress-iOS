import SwiftUI

struct ReaderSubscriptionHelper {
    let contextManager: CoreDataStackSwift = ContextManager.shared

    func followSite(withURL siteURL: String) async throws {
        guard let url = makeURL(fromUserInput: siteURL) else {
            throw ReaderFollowSiteError.invalidURL
        }
        try await withUnsafeThrowingContinuation { continuation in
            let service = ReaderSiteService(coreDataStack: contextManager)
            service.followSite(by: url, success: {
                postSiteFollowedNotification(siteURL: url)
                continuation.resume(returning: ())
            }, failure: { error in
                DDLogError("Could not follow site: \(String(describing: error))")
                continuation.resume(throwing: error ?? URLError(.unknown))
            })
        }
    }

    private func postSiteFollowedNotification(siteURL: URL) {
        let service = ReaderSiteService(coreDataStack: contextManager)
        service.topic(withSiteURL: siteURL, success: { topic in
            if let topic = topic {
                NotificationCenter.default.post(name: .ReaderSiteFollowed, object: nil, userInfo: [ReaderNotificationKeys.topic: topic])
            }
        }, failure: { error in
            DDLogError("Unable to find topic by siteURL: \(String(describing: error?.localizedDescription))")
        })
    }

    func unfollow(_ site: ReaderSiteTopic) {
        NotificationCenter.default.post(name: .ReaderTopicUnfollowed, object: nil, userInfo: [ReaderNotificationKeys.topic: site])
        let service = ReaderTopicService(coreDataStack: contextManager)
        service.toggleFollowing(forSite: site, success: { _ in
            // Do nothing
        }, failure: { _, error in
            DDLogError("Could not unfollow site: \(String(describing: error))")
            Notice(title: ReaderFollowedSitesViewController.Strings.failedToUnfollow, message: error?.localizedDescription, feedbackType: .error).post()
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
