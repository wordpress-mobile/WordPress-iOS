import Foundation
import Testing

@testable import WordPressMediaLibrary

struct UploadsEmptyStateTrackerTests {
    private let first = UUID()
    private let second = UUID()

    @Test func startsWithNoUploads() {
        #expect(UploadsEmptyStateTracker().state == .noUploads)
    }

    @Test func lastUploadFinishingShowsAllUploaded() {
        var tracker = UploadsEmptyStateTracker()
        tracker.listChanged(from: [first, second], to: [second])
        tracker.listChanged(from: [second], to: [])
        #expect(tracker.state == .allUploaded)
    }

    @Test func userRemovingTheLastRowShowsNoUploads() {
        var tracker = UploadsEmptyStateTracker()
        tracker.userWillRemove([first])
        tracker.listChanged(from: [first], to: [])
        #expect(tracker.state == .noUploads)
    }

    @Test func cancellingAllRowsShowsNoUploads() {
        var tracker = UploadsEmptyStateTracker()
        tracker.userWillRemove([first, second])
        tracker.listChanged(from: [first, second], to: [])
        #expect(tracker.state == .noUploads)
    }

    @Test func finishingAlongsideAUserRemovalShowsAllUploaded() {
        var tracker = UploadsEmptyStateTracker()
        tracker.userWillRemove([first])
        tracker.listChanged(from: [first, second], to: [])
        #expect(tracker.state == .allUploaded)
    }

    @Test func removalOfAnEarlierBatchDoesNotCarryOver() {
        var tracker = UploadsEmptyStateTracker()
        tracker.userWillRemove([first])
        tracker.listChanged(from: [first], to: [])
        // A new upload starts while the screen is open, then finishes.
        tracker.listChanged(from: [], to: [second])
        tracker.listChanged(from: [second], to: [])
        #expect(tracker.state == .allUploaded)
    }
}
