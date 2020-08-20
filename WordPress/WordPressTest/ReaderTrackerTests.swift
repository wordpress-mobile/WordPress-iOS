import UIKit
import XCTest
import Nimble

@testable import WordPress

class ReaderTrackerTests: XCTestCase {
    func testGetData() {
        let tracker = ReaderTracker()

        expect(tracker.data()).to(equal([
            "time_in_main_reader": 0,
            "time_in_reader_filtered_list": 0,
            "time_in_reader_post": 0
        ]))
    }
}
