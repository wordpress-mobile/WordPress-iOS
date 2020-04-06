import XCTest
@testable import WordPress

class PublishSettingsViewControllerTests: XCTestCase {

    private var contextManager: TestContextManager!
    private var context: NSManagedObjectContext!

    override func setUp() {
        contextManager = TestContextManager()
        context = contextManager.mainContext
    }

    override func tearDown() {
        contextManager.mainContext.reset()
        contextManager = nil
        context = nil
    }

    func testViewModelDateScheduled() {
        let testDate = Date().addingTimeInterval(5000)

        let post = PostBuilder(context).with(dateCreated: testDate).drafted().withRemote().build()

        var viewModel = PublishSettingsViewModel(post: post)
        XCTAssertEqual(viewModel.date, testDate, "Date should exist in view model")

        if case PublishSettingsViewModel.State.scheduled(_) = viewModel.state {
            // Success
        } else {
            XCTFail("View model should be scheduled")
        }

        viewModel.setDate(testDate)

        if case PublishSettingsViewModel.State.scheduled(_) = viewModel.state {
            // Success
        } else {
            XCTFail("View model should be scheduled instead of \(viewModel.state)")
        }
    }

    func testViewModelDateImmediately() {
        let testDate = Date()

        let post = PostBuilder(context).drafted().withRemote().build()

        var viewModel = PublishSettingsViewModel(post: post)
        XCTAssertNil(viewModel.date, "Date should not exist in view model")

        if case PublishSettingsViewModel.State.immediately = viewModel.state {
            // Success
        } else {
            XCTFail("View model should be immediately instead of \(viewModel.state)")
        }

        viewModel.setDate(testDate)

        if case PublishSettingsViewModel.State.published(_) = viewModel.state {
            // Success
        } else {
            XCTFail("View model should be published instead of \(viewModel.state)")
        }
    }

    func testViewModelDatePublished() {
        let testDate = Date()

        let post = PostBuilder(context).with(dateCreated: testDate).published().withRemote().build()

        var viewModel = PublishSettingsViewModel(post: post)
        XCTAssertEqual(viewModel.date, testDate, "Date should exist in view model")

        if case PublishSettingsViewModel.State.published(_) = viewModel.state {
            // Success
        } else {
            XCTFail("View model should be published instead of \(viewModel.state)")
        }

        viewModel.setDate(testDate)

        if case PublishSettingsViewModel.State.published(_) = viewModel.state {
            // Success
        } else {
            XCTFail("View model should be published instead of \(viewModel.state)")
        }
    }

    /// Tests that our display date is properly formatted and converted
    func testDisplayDate() {

        let timeZoneOffset = -1

        let testDate = Date(timeIntervalSinceReferenceDate: 0)

        let post = PostBuilder(context).with(dateCreated: testDate).drafted().withRemote().build()

        // Set our blog's time zone slightly offset from UTC
        let newValue = OffsetTimeZone(offset: Float(timeZoneOffset))

        // Need to use options here instead of blog.settings because BlogService uses those instead of the properties. No idea why.
        post.blog.options = ["timezone": ["value": newValue.timezoneString], "gmt_offset": ["value": newValue.gmtOffset as NSNumber? ]]

        let viewModel = PublishSettingsViewModel(post: post, context: self.context)

        // Create a date formatter that converts to the original UTC date
        let adjustedFormatter = viewModel.dateTimeFormatter.copy() as! DateFormatter
        adjustedFormatter.timeZone = TimeZone(secondsFromGMT: 0)

        // Generate formatted string and check that converting straight from that string is NOT the same as original date (should be earlier)
        let formattedString = viewModel.dateTimeFormatter.string(from: post.dateCreated!)
        let date = adjustedFormatter.date(from: formattedString)
        XCTAssertNotEqual(date, testDate, "Dates should not be equal")

        // Adjust the original date and check that it matches, thus verifying that our formatter is properly formatting
        let timeZoneAdjustedDate = testDate.addingTimeInterval(TimeInterval(timeZoneOffset * 60 * 60))
        XCTAssertEqual(timeZoneAdjustedDate, date, "Formatted date string should equal the adjusted date object")
    }
}

extension PublishSettingsViewControllerTests {
    // MARK: - Private Helpers
    fileprivate func newSettings() -> BlogSettings {
        let context = contextManager.mainContext
        let name = BlogSettings.classNameWithoutNamespaces()
        let entity = NSEntityDescription.insertNewObject(forEntityName: name, into: context)

        return entity as! BlogSettings
    }
}
