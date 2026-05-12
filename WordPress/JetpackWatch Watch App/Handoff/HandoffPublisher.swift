import Foundation

@MainActor
final class HandoffPublisher {
    static let activityType = "com.automattic.jetpack.voice-note-draft"

    private(set) var currentActivity: NSUserActivity?

    func publishDraftReady(postID: Int64, siteID: Int64) {
        let activity = NSUserActivity(activityType: Self.activityType)
        activity.title = "Open voice-note draft"
        activity.userInfo = ["postID": postID, "siteID": siteID]
        activity.isEligibleForHandoff = true
        activity.isEligibleForPublicIndexing = false
        activity.becomeCurrent()
        currentActivity = activity
    }

    func clear() {
        currentActivity?.invalidate()
        currentActivity = nil
    }
}
