import Foundation

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
}
