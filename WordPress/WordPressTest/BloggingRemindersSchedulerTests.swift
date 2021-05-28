import XCTest
@testable import WordPress

class BloggingRemindersSchedulerTests: XCTestCase {

    func testNewlyCreatedBloggingReminderStoreHasNoScheduleForUnscheduledBlog() {

        let scheduler = BloggingRemindersScheduler()
        /*
        
        let tempFile = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent("testBlogReminders_" + UUID().uuidString + ".plist")
        let blogIdentifier = URL(string: "someBlog")!
        let store: BloggingRemindersStore

        do {
            store = try BloggingRemindersStore(dataFileURL: tempFile)
        } catch {
            XCTFail(error.localizedDescription)
            return
        }

        XCTAssertEqual(store.scheduledReminders(for: blogIdentifier), .none)*/
    }
}
