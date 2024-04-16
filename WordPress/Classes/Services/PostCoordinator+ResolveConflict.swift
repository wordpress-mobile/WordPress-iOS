import Foundation

extension PostCoordinator {
    enum NotificationKey {
        static let postConflictResolved = "PostConflictResolvedNotificationKey"
    }

    func postConflictResolvedNotification(for post: AbstractPost) {
        NotificationCenter.default.post(name: .postConflictResolved, object: nil, userInfo: [NotificationKey.postConflictResolved: post])
    }
}

extension NSNotification.Name {
    /// Fired when a post conflict is resolved
    static let postConflictResolved = NSNotification.Name("PostConflictResolved")
}
