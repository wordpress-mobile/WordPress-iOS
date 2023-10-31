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

    func testUnschedulingRemindersRemovesEntryForBlog() {
        let firstBlogID = URL(string: "someBlog")!
        let secondBlogID = URL(string: "someBlog2")!

        let tempFile = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent("testBlogReminders_" + UUID().uuidString + ".plist")
        let configuration = [
            firstBlogID: BloggingRemindersStore.ScheduledReminders.weekdays([
                .init(weekday: .monday, notificationID: UUID().uuidString),
                .init(weekday: .tuesday, notificationID: UUID().uuidString),
            ]),
            secondBlogID: BloggingRemindersStore.ScheduledReminders.weekdays([
                .init(weekday: .monday, notificationID: UUID().uuidString),
                .init(weekday: .wednesday, notificationID: UUID().uuidString),
            ])
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

        XCTAssertEqual(store.configuration, configuration)

        try? store.save(scheduledReminders: .none, for: firstBlogID)

        // There should now be no entry for the first blog
        XCTAssertEqual(store.scheduledReminders(for: firstBlogID), .none)

        // There should still be an entry for the second blog
        XCTAssertEqual(store.scheduledReminders(for: secondBlogID), configuration[secondBlogID])
    }
}
