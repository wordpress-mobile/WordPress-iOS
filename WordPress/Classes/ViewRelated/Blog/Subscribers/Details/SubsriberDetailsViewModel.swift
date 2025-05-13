import Foundation
import WordPressKit

@MainActor
struct SubsriberDetailsViewModel {
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

    static func mock() -> SubsriberDetailsViewModel {
        SubsriberDetailsViewModel(blog: .mock(), subscriberID: 1)
    }

    func getDetails() async throws -> SubscribersServiceRemote.GetSubscriberDetailsResponse {
        try await blog.getSubscribersService()
            .getSubsciberDetails(siteID: blog.dotComSiteID, subscriberID: subscriberID)
    }

    func getStats() async throws -> SubscribersServiceRemote.GetSubscriberStatsResponse {
        try await blog.getSubscribersService()
            .getSubsciberStats(siteID: blog.dotComSiteID, subscriberID: subscriberID)
    }

    func delete(_ subscriber: SubscribersServiceRemote.SubsciberBasicInfoResponse) async throws {
        try await blog.getSubscribersService()
            .deleteSubscriber(subscriber, siteID: blog.dotComSiteID)
    }

    func formattedDateSubscribed(_ date: Date) -> String {
        let absolute = date.formatted(date: .abbreviated, time: .shortened)
        let relative = relativeFormatter.localizedString(for: date, relativeTo: .now)
        return absolute + " (\(relative))"
    }
}

extension SubscribersServiceRemote {
    func deleteSubscriber(_ subscriber: SubscribersServiceRemote.SubsciberBasicInfoResponse, siteID: Int) async throws {
        let service = PeopleServiceRemote(wordPressComRestApi: wordPressComRestApi)
        try await withUnsafeThrowingContinuation { continuation in
            if subscriber.isDotComUser {
                service.deleteFollower(siteID, userID: subscriber.dotComUserID, success: {
                    continuation.resume()
                }, failure: {
                    continuation.resume(throwing: $0)
                })
            } else {
                service.deleteEmailFollower(siteID, userID: subscriber.subscriberID, success: {
                    continuation.resume()
                }, failure: {
                    continuation.resume(throwing: $0)
                })
            }
        }
    }
}
