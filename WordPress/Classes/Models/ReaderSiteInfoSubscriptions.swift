import Foundation
import CoreData


@objc public class ReaderSiteInfoSubscriptionPost: NSManagedObject {
    @NSManaged open var siteTopic: ReaderSiteTopic
    @NSManaged open var sendPosts: Bool

    class func createOrUpdate(from remoteSiteInfo: RemoteReaderSiteInfo, topic: ReaderSiteTopic, context: NSManagedObjectContext) -> ReaderSiteInfoSubscriptionPost? {
        guard remoteSiteInfo.postSubscription.wp_isValidObject() else {
            return nil
        }

        var subscription = topic.postSubscription
        if !(subscription?.wp_isValidObject() ?? false) {
            subscription = ReaderSiteInfoSubscriptionPost(context: context)
        }

        subscription?.siteTopic = topic
        subscription?.sendPosts = remoteSiteInfo.postSubscription.sendPosts

        return subscription
    }
}


@objc public class ReaderSiteInfoSubscriptionEmail: NSManagedObject {
    @NSManaged open var siteTopic: ReaderSiteTopic
    @NSManaged open var sendPosts: Bool
    @NSManaged open var sendComments: Bool
    @NSManaged open var postDeliveryFrequency: String

    class func createOrUpdate(from remoteSiteInfo: RemoteReaderSiteInfo, topic: ReaderSiteTopic, context: NSManagedObjectContext) -> ReaderSiteInfoSubscriptionEmail? {
        guard remoteSiteInfo.emailSubscription?.wp_isValidObject() ?? false else {
            return nil
        }

        var subscription = topic.emailSubscription
        if !(subscription?.wp_isValidObject() ?? false) {
            subscription = ReaderSiteInfoSubscriptionEmail(context: context)
        }

        subscription?.siteTopic = topic
        subscription?.sendPosts = remoteSiteInfo.emailSubscription.sendPosts
        subscription?.sendComments = remoteSiteInfo.emailSubscription.sendComments
        subscription?.postDeliveryFrequency = remoteSiteInfo.emailSubscription.postDeliveryFrequency

        return subscription
    }
}
