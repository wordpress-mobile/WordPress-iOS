import Foundation
import XCTest
@testable import WordPress


// MARK: - NotificationReplyStore Unit Tests!
//
class NotificationReplyStoreTests: XCTestCase {

    /// Testing Keys
    ///
    struct Testing {
        static let text1 = "This is a sample reply"
        static let text2 = "This is the second sample!"
        static let key1 = "1234"
        static let key2 = "4321"
    }

    /// Reset Reply Storage everytime!
    ///
    override func tearDown() {
        NotificationReplyStore.shared.reset()
    }

    /// Verifies that `loadReply` returns *nil* for keys never seen before.
    ///
    func testLoadReplyReturnsNilWheneverThereIsNoReplyStored() {
        let store = NotificationReplyStore(now: Date())
        XCTAssertNil(store.loadReply(for: Testing.key1))
    }

    /// Verifies that `loadReply` returns previously stored replies.
    ///
    func testLoadEffectivelyRetrievesStoredEntries() {
        let store = NotificationReplyStore(now: Date())

        store.store(reply: Testing.text1, for: Testing.key1)
        store.store(reply: Testing.text2, for: Testing.key2)

        XCTAssertEqual(store.loadReply(for: Testing.key1), Testing.text1)
        XCTAssertEqual(store.loadReply(for: Testing.key2), Testing.text2)
    }

    /// Verifies that replies "younger" than 7 days do not get nuked.
    ///
    func testNonOudatedEntriesArePreserved() {
        let sevenDaysAgoInSeconds = TimeInterval(3600 * 24 * -6)
        let sevenDaysAgoAsDate = Date(timeIntervalSinceNow: sevenDaysAgoInSeconds)

        let sometimeInThePast = NotificationReplyStore(now: sevenDaysAgoAsDate)
        sometimeInThePast.store(reply: Testing.text1, for: Testing.key1)
        sometimeInThePast.store(reply: Testing.text2, for: Testing.key2)

        let nowadays = NotificationReplyStore(now: Date())
        XCTAssertEqual(nowadays.loadReply(for: Testing.key1), Testing.text1)
        XCTAssertEqual(nowadays.loadReply(for: Testing.key2), Testing.text2)
    }

    /// Verifies that replies older than 7 days get nucked.
    ///
    func testOudatedEntriesAreNuked() {
        let sevenDaysAgoInSeconds = TimeInterval(3600 * 24 * -7)
        let sevenDaysAgoAsDate = Date(timeIntervalSinceNow: sevenDaysAgoInSeconds)

        let sometimeInThePast = NotificationReplyStore(now: sevenDaysAgoAsDate)
        sometimeInThePast.store(reply: Testing.key1, for: Testing.text1)
        sometimeInThePast.store(reply: Testing.key2, for: Testing.text2)

        let nowadays = NotificationReplyStore(now: Date())
        XCTAssertNil(nowadays.loadReply(for: Testing.key1))
        XCTAssertNil(nowadays.loadReply(for: Testing.key2))
    }
}
