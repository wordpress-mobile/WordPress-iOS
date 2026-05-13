import Testing
import Foundation
@testable import JetpackWatch_Watch_App

@Suite("HandoffPublisher")
@MainActor
struct HandoffPublisherTests {

    @Test func publishDraftReady_sets_activity_with_post_and_site_ids() {
        let publisher = HandoffPublisher()
        publisher.publishDraftReady(postID: 789, siteID: 42)

        let activity = publisher.currentActivity
        #expect(activity?.activityType == HandoffPublisher.activityType)
        #expect(activity?.userInfo?["postID"] as? Int64 == 789)
        #expect(activity?.userInfo?["siteID"] as? Int64 == 42)
    }

    @Test func clear_invalidates_the_activity() {
        let publisher = HandoffPublisher()
        publisher.publishDraftReady(postID: 1, siteID: 1)
        publisher.clear()
        #expect(publisher.currentActivity == nil)
    }

    @Test func publishing_a_second_activity_replaces_the_first() {
        let publisher = HandoffPublisher()
        publisher.publishDraftReady(postID: 1, siteID: 1)
        let first = publisher.currentActivity!

        publisher.publishDraftReady(postID: 2, siteID: 1)
        let second = publisher.currentActivity!

        // The current activity must be a fresh object (the prior one was invalidated and replaced).
        #expect(second !== first)
        // The new activity carries the updated postID.
        #expect(second.userInfo?["postID"] as? Int64 == 2)
    }
}
