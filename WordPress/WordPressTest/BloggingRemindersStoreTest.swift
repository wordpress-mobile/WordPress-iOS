import XCTest
@testable import WordPress

class BloggingRemindersStoreTests: XCTestCase {

    func testNewlyCreatedBloggingReminderStoreHasNoScheduleForUnscheduledBlog() {
        let tempFile = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent("testBlogReminders_" + UUID().uuidString + ".plist")
        let blogIdentifier = URL(string: "someBlog")!
        let store: BloggingRemindersStore

        do {
            store = try BloggingRemindersStore(dataFileURL: tempFile)
        } catch {
            XCTFail(error.localizedDescription)
            return
        }

        XCTAssertEqual(store.scheduledReminders(for: blogIdentifier), .none)
    }

    func testPreexistingBloggingReminderStoreMaintainsSchedule() {
        let tempFile = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent("testBlogReminders_" + UUID().uuidString + ".plist")
        let configuration = [
            URL(string: "someBlog")!: BloggingRemindersStore.ScheduledReminders.weekdays([
                .init(weekday: .monday, notificationID: UUID().uuidString),
                .init(weekday: .tuesday, notificationID: UUID().uuidString),
            ]),
            URL(string: "someBlog2")!: BloggingRemindersStore.ScheduledReminders.weekdays([
                .init(weekday: .monday, notificationID: UUID().uuidString),
                .init(weekday: .wednesday, notificationID: UUID().uuidString),
            ]),
            URL(string: "someBlog3")!: BloggingRemindersStore.ScheduledReminders.weekdays([
                .init(weekday: .saturday, notificationID: UUID().uuidString),
                .init(weekday: .sunday, notificationID: UUID().uuidString),
            ]),
        ]
        let store: BloggingRemindersStore

        do {
            store = try BloggingRemindersStore(dataFileURL: tempFile)

            for (blogIdentifier, scheduledReminders) in configuration {
                try store.save(scheduledReminders: scheduledReminders, for: blogIdentifier)
            }
        } catch {
            XCTFail(error.localizedDescription)
            return
        }

        // To simulate another launch of the app, we just create another store using
        // the same data file, and compare the schedules.

        let secondLaunchStore: BloggingRemindersStore

        do {
            secondLaunchStore = try BloggingRemindersStore(dataFileURL: tempFile)
        } catch {
            XCTFail(error.localizedDescription)
            return
        }

        XCTAssertEqual(secondLaunchStore.configuration, store.configuration)
    }
}
