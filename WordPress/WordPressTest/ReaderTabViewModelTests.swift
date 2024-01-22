@testable import WordPress
import XCTest
import WordPressFlux
import CoreData


class MockItemsStore: ItemsStore {
    let changeDispatcher = Dispatcher<Void>()

    var items: [ReaderTabItem] = [ReaderTabItem(ReaderContent(topic: nil, contentType: .saved))]

    var newItems = [ReaderTabItem(ReaderContent(topic: nil, contentType: .selfHostedFollowing)), ReaderTabItem(ReaderContent(topic: nil, contentType: .selfHostedFollowing))]

    var getItemsExpectation: XCTestExpectation?

    func getItems() {
        items = newItems
        getItemsExpectation?.fulfill()
        emitChange()
    }
}

class MockContentController: UIViewController, ReaderContentViewController {

    var setContentExpectation: XCTestExpectation?

    func setContent(_ content: ReaderContent) {
        setContentExpectation?.fulfill()
    }
}

class MockSettingsPresenter: ScenePresenter {

    var presentExpectation: XCTestExpectation?

    var presentedViewController: UIViewController?

    func present(on viewController: UIViewController, animated: Bool, completion: (() -> Void)?) {
        presentExpectation?.fulfill()
    }
}

class ReaderTabViewModelTests: CoreDataTestCase {

    var makeContentControllerExpectation: XCTestExpectation?

    var store: MockItemsStore!
    var viewModel: ReaderTabViewModel!
    var settingsPresenter: MockSettingsPresenter!

    override func setUp() {
        store = MockItemsStore()
        settingsPresenter = MockSettingsPresenter()
        viewModel = ReaderTabViewModel(readerContentFactory: readerContentControllerFactory(_:),
                                       searchNavigationFactory: { },
                                       tabItemsStore: store,
                                       settingsPresenter: settingsPresenter)
    }

    override func tearDown() {
        viewModel = nil
        store = nil
        settingsPresenter = nil
        makeContentControllerExpectation = nil
    }

    func testRefreshTabBar() {
        // Given
        let setTabBarItemsExpectation = expectation(description: "tab bar items were set")
        store.getItemsExpectation = expectation(description: "Items were fetched")
        // When
        viewModel.onTabBarItemsDidChange { items, index in
            setTabBarItemsExpectation.fulfill()
            XCTAssertEqual(index, 0)
            XCTAssertEqual(items.map { $0.title }, ["Subscriptions", "Subscriptions"])
        }
        // Then
        viewModel.fetchReaderMenu()
        waitForExpectations(timeout: 4) { error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
        }
    }

    func testPresentManage() {
        // Given
        settingsPresenter.presentExpectation = expectation(description: "Settings screen was presented")
        // When
        let controller = UIViewController()
        viewModel.presentManage(filter: makeFilterProvider(), from: controller)
        // Then
        waitForExpectations(timeout: 4) { error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
        }
    }

    func testPresentFilterFromView() {
        // Given
        let filter = makeFilterProvider()
        let filterTappedExpectation = expectation(description: "Filter button was tapped")
        viewModel.filterTapped = { filter, view, completion in
            filterTappedExpectation.fulfill()
        }
        let viewController = UIViewController()
        // When
        viewModel.didTapStreamFilterButton(with: filter)
        // Then
        waitForExpectations(timeout: 4) { error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
        }
    }

    func testResetFilter() {
        // Given
        let selectedTopic = ReaderAbstractTopic(context: mainContext)
        selectedTopic.title = "selected topic"
        viewModel.tabItems = [ReaderTabItem(ReaderContent(topic: selectedTopic))]

        let setContenttopicExpectation = expectation(description: "content topic was set")
        viewModel.setContent = {
            setContenttopicExpectation.fulfill()
            XCTAssertEqual($0.topic!.title, "selected topic")
        }
        // When
        viewModel.resetStreamFilter()
        // Then
        waitForExpectations(timeout: 4) { error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
        }
    }

    func testMakeChildContentController() {
        // Given
        makeContentControllerExpectation = expectation(description: "Content controller was constructed")

        let topic = ReaderAbstractTopic(context: mainContext)
        topic.title = "content topic"
        let content = ReaderContent(topic: topic)
        store.items = [ReaderTabItem(content)]
        viewModel.fetchReaderMenu()
        // When
        let controller = viewModel.makeChildContentViewController(at: 0)
        viewModel.setContent?(content)
        // Then
        XCTAssert(controller is MockContentController)
        waitForExpectations(timeout: 4) { error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
        }
    }
}


// MARK: - Helpers
extension ReaderTabViewModelTests {

    private func readerContentControllerFactory(_ content: ReaderContent) -> ReaderContentViewController {
        makeContentControllerExpectation?.fulfill()
        let controller = MockContentController()
        controller.setContentExpectation = expectation(description: "Topic was set")
        return controller
    }

    private func makeFilterProvider() -> FilterProvider {
        return FilterProvider(title: { _ in "Test" },
                       accessibilityIdentifier: "Test",
                       cellClass: UITableViewCell.self,
                       reuseIdentifier: "Cell",
                       emptyTitle: "Test",
                       emptyActionTitle: "Test",
                       section: .sites) { completion in
            completion(.success([]))
        }
    }
}
