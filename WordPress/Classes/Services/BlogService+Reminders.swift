import Foundation

extension BlogService {
    @objc func unscheduleBloggingReminders(for blogID: NSManagedObjectID) {
        let context = ContextManager.shared.mainContext
        context.performAndWait {
            do {
                guard let blogInContext = try context.existingObject(with: blogID) as? Blog else {
                    return
                }
                let scheduler = try ReminderScheduleCoordinator()
                scheduler.schedule(.none, for: blogInContext, completion: { _ in })
                // We're currently not propagating success / failure here, as it's
                // it's only used when removing blogs or accounts, and there's
                // no extra action we can take if it fails anyway.
            } catch {
                DDLogError("Could not instantiate the reminders scheduler: \(error.localizedDescription)")
            }
        }
    }
}
