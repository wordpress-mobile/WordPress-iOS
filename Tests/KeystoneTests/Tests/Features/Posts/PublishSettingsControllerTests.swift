import XCTest
@testable import WordPress
@testable import WordPressData

class PublishSettingsViewControllerTests: CoreDataTestCase {

    func testViewModelDateScheduled() {
        let testDate = Date().addingTimeInterval(5000)

        let post = PostBuilder(mainContext).with(dateCreated: testDate).drafted().withRemote().build()

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

        let post = PostBuilder(mainContext).drafted().withRemote().build()

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

        let post = PostBuilder(mainContext).with(dateCreated: testDate).published().withRemote().build()

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
