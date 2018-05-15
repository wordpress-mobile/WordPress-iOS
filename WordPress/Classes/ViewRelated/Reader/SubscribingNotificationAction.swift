final class SubscribingNotificationAction {
    func execute(for siteID: NSNumber?, context: NSManagedObjectContext, value: Bool) {
        toggleSubscribingNotifications(for: siteID, subscribe: value, context: context)
    }

    fileprivate func toggleSubscribingNotifications(for siteID: NSNumber?, subscribe: Bool, context: NSManagedObjectContext) {
        guard let siteID = siteID else {
            return
        }

        let service = ReaderTopicService(managedObjectContext: context)
        service.toggleSubscribingNotifications(for: siteID, subscribe: subscribe)
    }
}
