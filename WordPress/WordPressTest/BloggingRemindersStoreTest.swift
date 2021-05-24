import XCTest
@testable import WordPress

class BloggingRemindersStoreTests: XCTestCase {

    func testNewlyCreatedBloggingReminderStoreHasNoSchedule() {
        let tempFile = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent("testBlogReminders_" + UUID().uuidString + ".plist")
        let store = BloggingRemindersStore(dataFileURL: tempFile)

        XCTAssertEqual(store.schedule, .none)
    }

    func testPreexistingBloggingReminderStoreMaintainsSchedule() {
        let tempFile = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent("testBlogReminders_" + UUID().uuidString + ".plist")
        let store = BloggingRemindersStore(dataFileURL: tempFile)

        let days: [BloggingRemindersStore.Weekday] = [
            .monday(notificationID: UUID().uuidString),
            .tuesday(notificationID: UUID().uuidString),
            .wednesday(notificationID: UUID().uuidString),
            .thursday(notificationID: UUID().uuidString),
            .friday(notificationID: UUID().uuidString),
            .saturday(notificationID: UUID().uuidString),
            .sunday(notificationID: UUID().uuidString),
        ]
        store.schedule = .weekdays(days)

        // To simulate another launch of the app, we just create another store and compare the schedules

        let secondLaunchStore = BloggingRemindersStore(dataFileURL: tempFile)
        XCTAssertEqual(secondLaunchStore.schedule, store.schedule)
    }
}
