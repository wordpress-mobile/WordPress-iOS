/// Encapsulates a command to toggle subscribing to notifications for a site
final class ReaderSubscribingNotificationAction {
    func execute(for siteID: NSNumber?, context: NSManagedObjectContext, value: Bool) {
        toggleSubscribingNotifications(for: siteID, subscribe: value, context: context)
    }

    fileprivate func toggleSubscribingNotifications(for siteID: NSNumber?, subscribe: Bool, context: NSManagedObjectContext) {
        guard let siteID = siteID else {
            return
        }

        let service = ReaderTopicService(managedObjectContext: context)
        service.toggleSubscribingNotifications(for: siteID.intValue, subscribe: subscribe)
    }
}
