import Foundation

/// This extension emits notification so the posts card on
/// the Dashboard can listen to them
///
/// Basically this is needed to show a card when a post is
/// scheduled or drafted and this card is not appearing
extension PostCoordinator {
    func notifyDashboardOfPostScheduled() {
        NotificationCenter.default.post(name: .showScheduledCard, object: nil)
    }

    func notifyDashboardOfDraftSaved() {
        NotificationCenter.default.post(name: .showDraftsCard, object: nil)
    }
}

extension NSNotification.Name {
    /// Fired when a post is scheduled
    static let showScheduledCard = NSNotification.Name("ShowScheduledCard")

    /// Fired when a draft is saved
    static let showDraftsCard = NSNotification.Name("ShowDraftsCard")
}
