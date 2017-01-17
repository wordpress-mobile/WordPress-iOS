import XCTest
@testable import WordPress


// MARK: - RemoteNotification Unit Tests
//
class RemoteNotificationTests: XCTestCase {
    /// Tests that a Remote Notification gets correctly parsed, when initialized with a proper
    /// notification document.
    ///
    func testRemoteNotificationParsesAllFieldsCorrectly() {
        let document = loadDocument()
        guard let remote = RemoteNotification(document: document) else {
            XCTFail()
            return
        }

        XCTAssertEqual(remote.notificationId, "2671944253")
        XCTAssertEqual(remote.notificationHash, "235848772")
        XCTAssertEqual(remote.type, "yosemite")
        XCTAssertTrue(remote.read)
        XCTAssertEqual(remote.timestamp, "2016-10-25T17:47:45+00:00")
        XCTAssertEqual(remote.icon, "https://0.gravatar.com/avatar/")
        XCTAssertEqual(remote.url, "https://yosemite.blog")
        XCTAssertNotNil(remote.header)
        XCTAssertNotNil(remote.subject)
        XCTAssertNotNil(remote.title)
        XCTAssertNotNil(remote.body)
        XCTAssertNotNil(remote.meta)
    }


    /// Tests that a Remote Notification doesn't initialize whenever the ID field is missing.
    ///
    func testRemoteNotificationInitializerReturnsNilWheneverNoteIdIsMissing() {
        var document = loadDocument()
        document.removeValue(forKey: "id")

        let remote = RemoteNotification(document: document)
        XCTAssertNil(remote)
    }


    /// Tests that a Remote Notification doesn't initialize whenever the ID field is missing.
    ///
    func testRemoteNotificationInitializerReturnsNilWheneverNoteHashIsMissing() {
        var document = loadDocument()
        document.removeValue(forKey: "note_hash")

        let remote = RemoteNotification(document: document)
        XCTAssertNil(remote)
    }
}


// MARK: - Private Helpers
//
private extension RemoteNotificationTests {
    /// Retrieves a Remote Notification's Document
    ///
    func loadDocument() -> [String: AnyObject] {
        let path = Bundle(for: type(of: self)).path(forResource: "remote-notification", ofType: "json")!
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            return try JSONSerialization.jsonObject(with: data as Data, options: .allowFragments) as! [String: AnyObject]
        } catch {
            fatalError()
        }
    }
}
