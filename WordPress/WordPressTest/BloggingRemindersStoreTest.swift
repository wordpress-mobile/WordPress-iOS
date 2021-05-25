import XCTest
@testable import WordPress

class BloggingRemindersStoreTests: XCTestCase {

    func testNewlyCreatedBloggingReminderStoreHasNoSchedule() {
        let tempFile = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent("testBlogReminders_" + UUID().uuidString + ".plist")
        let store = BloggingRemindersStore(dataFileURL: tempFile)

        XCTAssertEqual(store.scheduledReminders, .none)
    }

    func testPreexistingBloggingReminderStoreMaintainsSchedule() {
        let tempFile = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent("testBlogReminders_" + UUID().uuidString + ".plist")
        let store = BloggingRemindersStore(dataFileURL: tempFile)

        let days: [BloggingRemindersStore.ScheduledWeekday] = [
            .init(weekday: .monday, notificationID: UUID().uuidString),
            .init(weekday: .tuesday, notificationID: UUID().uuidString),
            .init(weekday: .wednesday, notificationID: UUID().uuidString),
            .init(weekday: .thursday, notificationID: UUID().uuidString),
            .init(weekday: .friday, notificationID: UUID().uuidString),
            .init(weekday: .saturday, notificationID: UUID().uuidString),
            .init(weekday: .sunday, notificationID: UUID().uuidString),
        ]
        store.scheduledReminders = .weekdays(days)

        // To simulate another launch of the app, we just create another store and compare the schedules

        let secondLaunchStore = BloggingRemindersStore(dataFileURL: tempFile)
        XCTAssertEqual(secondLaunchStore.scheduledReminders, store.scheduledReminders)
    }
}
