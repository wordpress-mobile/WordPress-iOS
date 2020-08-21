import UIKit
import XCTest
import Nimble

@testable import WordPress

class ReaderTrackerTests: XCTestCase {

    /// Return 20s as the time spent in Reader
    ///
    func testTrackTimeSpentInMainReader() {
        let nowMock = DateMock(startTime: Date(), endTime: Date() + 20)
        let tracker = ReaderTracker(now: nowMock.now)
        tracker.start(.main)

        tracker.stop(.main)

        expect(tracker.data()).to(equal([
            "time_in_main_reader": 20,
            "time_in_reader_filtered_list": 0,
            "time_in_reader_post": 0
        ]))
    }

    /// Return 16s as the time spent in filtered list
    ///
    func testTrackTimeSpentInFilteredList() {
        let nowMock = DateMock(startTime: Date(), endTime: Date() + 15.5)
        let tracker = ReaderTracker(now: nowMock.now)
        tracker.start(.filteredList)

        tracker.stop(.filteredList)

        expect(tracker.data()).to(equal([
            "time_in_main_reader": 0,
            "time_in_reader_filtered_list": 16,
            "time_in_reader_post": 0
        ]))
    }

    /// Return 60s as the time spent in post
    ///
    func testTrackTimeSpentInPost() {
        let nowMock = DateMock(startTime: Date(), endTime: Date() + 60)
        let tracker = ReaderTracker(now: nowMock.now)
        tracker.start(.readerPost)

        tracker.stop(.readerPost)

        expect(tracker.data()).to(equal([
            "time_in_main_reader": 0,
            "time_in_reader_filtered_list": 0,
            "time_in_reader_post": 60
        ]))
    }

}

private class DateMock {
    private let startTime: Date
    private let endTime: Date
    var called = 0

    init(startTime: Date, endTime: Date) {
        self.startTime = startTime
        self.endTime = endTime
    }

    func now() -> Date {
        called += 1
        return called == 1 ? startTime : endTime
    }
}
