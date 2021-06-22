import Foundation

extension BlogService {
    @objc func unscheduleBloggingReminders(for blog: Blog) {
        do {
            let scheduler = try BloggingRemindersScheduler()
            scheduler.schedule(.none, for: blog, completion: { _ in })
            // We're currently not propagating success / failure here, as it's
            // it's only used when removing blogs or accounts, and there's
            // no extra action we can take if it fails anyway.
        } catch {
            DDLogError("Could not instantiate the blogging reminders scheduler: \(error.localizedDescription)")
        }
    }
}
