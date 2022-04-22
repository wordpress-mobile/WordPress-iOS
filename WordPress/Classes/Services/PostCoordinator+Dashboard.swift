import Foundation

/// This extension emits notification so the posts card on
/// the Dashboard can listen to them
///
/// Basically this is needed to show a card when a post is
/// scheduled or drafted and this card is not appearing
extension PostCoordinator {
    func notifyNewPostScheduled() {
        NotificationCenter.default.post(name: .newPostScheduled, object: nil)
    }

    func notifyNewPostCreated() {
        NotificationCenter.default.post(name: .newPostCreated, object: nil)
    }

    func notifyNewPostPublished() {
        NotificationCenter.default.post(name: .newPostPublished, object: nil)
    }
}

extension NSNotification.Name {
    /// Fired when a post is scheduled
    static let newPostScheduled = NSNotification.Name("NewPostScheduled")

    /// Fired when a draft is saved
    static let newPostCreated = NSNotification.Name("NewPostCreated")

    /// Fired when a post is published
    static let newPostPublished = NSNotification.Name("NewPostPublished")
}
