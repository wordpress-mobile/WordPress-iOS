import Foundation

/// WordPress event handler for background task events.
/// This class knows specifically about how WordPress wants to log and track these events.
///
class WordPressBackgroundTaskEventHandler: BackgroundTaskEventHandler {
    func handle(_ event: BackgroundTaskEvent) {
        switch event {
        case .start(let identifier):
            DDLogInfo("Background task started: \(identifier)")
        case .error(let identifier, let error):
            DDLogError("Background task error: \(identifier) - Error: \(error)")
        case .expirationHandlerCalled(let identifier):
            DDLogError("Background task time expired: \(identifier)")
        case .taskCompleted(let identifier, let cancelled):
            DDLogInfo("Background task completed: \(identifier) - Cancelled: \(cancelled)")
        case .rescheduled(let identifier):
            DDLogInfo("Background task rescheduled: \(identifier)")
        }
    }
}
