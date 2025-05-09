import Foundation
import WordPressKit

@MainActor
struct SubsriberDetailsViewModel {
    let subscriberID: Int
    let subscriber: SubscribersServiceRemote.SubsciberBasicInfoResponse?

    private let blog: SubscribersBlog

    init(blog: SubscribersBlog, subscriber: SubscribersServiceRemote.SubsciberBasicInfoResponse) {
        self.blog = blog
        self.subscriberID = subscriber.subscriberID
        self.subscriber = subscriber
    }

    init(blog: SubscribersBlog, subscriberID: Int) {
        self.blog = blog
        self.subscriberID = subscriberID
        self.subscriber = nil
    }

    static func mock() -> SubsriberDetailsViewModel {
        SubsriberDetailsViewModel(blog: .mock(), subscriberID: 1)
    }

    func getDetails() async throws -> SubscribersServiceRemote.GetSubscriberDetailsResponse {
        try await getService().getSubsciberDetails(siteID: blog.dotComSiteID, subscriberID: subscriberID)
    }

    func getStats() async throws -> SubscribersServiceRemote.GetSubscriberStatsResponse {
        try await getService().getSubsciberStats(siteID: blog.dotComSiteID, subscriberID: subscriberID)
    }

    private func getService() throws -> SubscribersServiceRemote {
        guard let api = blog.getRestAPI() else {
            throw URLError(.unknown, userInfo: [NSLocalizedDescriptionKey: SharedStrings.Error.generic])
        }
        return SubscribersServiceRemote(wordPressComRestApi: api)
    }
}
