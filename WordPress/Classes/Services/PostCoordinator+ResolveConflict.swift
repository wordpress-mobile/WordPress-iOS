import Foundation

extension PostCoordinator {
    enum NotificationKey {
        static let postConflictResolvedPickingRemoteRevision = "PostConflictResolvedPickingRemoteRevisionNotificationKey"
    }

    func notifyConflictResolvedPickingLocalRevision() {
        NotificationCenter.default.post(name: .postConflictResolvedPickingLocalRevision, object: nil)
    }

    func notifyConflictResolvedPickingRemoteRevision(for post: AbstractPost) {
        NotificationCenter.default.post(name: .postConflictResolvedPickingRemoteRevision, object: nil, userInfo: [NotificationKey.postConflictResolvedPickingRemoteRevision: post])
    }
}

extension NSNotification.Name {
    /// Fired when a post conflict is resolved by picking the local revision
    static let postConflictResolvedPickingLocalRevision = NSNotification.Name("PostConflictResolvedPickingLocalRevision")

    /// Fired when a post conflict is resolved by picking the remote revision
    static let postConflictResolvedPickingRemoteRevision = NSNotification.Name("PostConflictResolvedPickingRemoteRevision")
}
