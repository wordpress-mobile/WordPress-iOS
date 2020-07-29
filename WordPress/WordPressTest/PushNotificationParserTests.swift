import XCTest

class PushNotificationParserTests: XCTestCase {

    // This test ensures that we maintain compatibilty with the v1 WordPress.com Push Notification System
    func testThatStringOnlyNotificationsAreParsedCorrectly() {
        let string = UUID().uuidString
        let note = UNMutableNotificationContent()
        note.userInfo = [
            "aps": [
                "alert": string
            ]
        ]

        XCTAssertEqual(string, note.alertString)
    }

    // This test ensures that we allow parsing v2 WordPress.com Push Notifications
    func testThatAlertObjectsWithTitlesAreParsedCorrectly() {
        let string = UUID().uuidString
        let note = UNMutableNotificationContent()
        note.userInfo = [
            "aps": [
                "alert": [
                    "title": string
                ]
            ]
        ]

        XCTAssertEqual(string, note.alertString)
    }
}
