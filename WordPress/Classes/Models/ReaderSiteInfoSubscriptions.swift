import Foundation
import CoreData


@objc public class ReaderSiteInfoSubscriptionPost: NSManagedObject {
    @NSManaged open var siteTopic: ReaderSiteTopic
    @NSManaged open var sendPosts: Bool
}


@objc public class ReaderSiteInfoSubscriptionEmail: NSManagedObject {
    @NSManaged open var siteTopic: ReaderSiteTopic
    @NSManaged open var sendPosts: Bool
    @NSManaged open var sendComments: Bool
    @NSManaged open var postDeliveryFrequency: String
}
