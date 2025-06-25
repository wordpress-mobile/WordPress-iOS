import Foundation
import WordPressKit

@MainActor
struct SubscriberDetailsViewModel {
    let subscriberID: Int
    let subscriber: SubscribersServiceRemote.SubsciberBasicInfoResponse?

    private let blog: SubscribersBlog

    private let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .numeric
        formatter.unitsStyle = .full
        return formatter
    }()

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

    static func mock() -> SubscriberDetailsViewModel {
        SubscriberDetailsViewModel(blog: .mock(), subscriberID: 1)
    }

    func getDetails() async throws -> SubscribersServiceRemote.GetSubscriberDetailsResponse {
        try await blog.makeSubscribersService()
            .getSubsciberDetails(siteID: blog.dotComSiteID, subscriberID: subscriberID)
    }

    func getStats() async throws -> SubscribersServiceRemote.GetSubscriberStatsResponse {
        try await blog.makeSubscribersService()
            .getSubsciberStats(siteID: blog.dotComSiteID, subscriberID: subscriberID)
    }

    func delete(_ subscriber: SubscribersServiceRemote.SubsciberBasicInfoResponse) async throws {
        try await blog.makeSubscribersService()
            .deleteSubscriber(subscriber, siteID: blog.dotComSiteID)
    }

    func formattedDateSubscribed(_ date: Date) -> String {
        let absolute = date.formatted(date: .abbreviated, time: .shortened)
        let relative = relativeFormatter.localizedString(for: date, relativeTo: .now)
        return absolute + " (\(relative))"
    }
}
