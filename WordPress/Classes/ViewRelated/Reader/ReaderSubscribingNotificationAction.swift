/// Encapsulates a command to toggle subscribing to notifications for a site
final class ReaderSubscribingNotificationAction {
    func execute(for siteID: NSNumber?, context: NSManagedObjectContext, subscribe: Bool, completion: (() -> Void)? = nil, failure: ((ReaderTopicServiceError?) -> Void)? = nil) {
        guard let siteID = siteID else {
            return
        }

        let service = ReaderTopicService(managedObjectContext: context)
        service.toggleSubscribingNotifications(for: siteID.intValue, subscribe: subscribe, completion, failure)
    }
}
