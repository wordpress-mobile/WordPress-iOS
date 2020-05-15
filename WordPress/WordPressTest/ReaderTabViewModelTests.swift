@testable import WordPress
import XCTest
import WordPressFlux


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

class ReaderTabViewModelTests: XCTestCase {

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
        viewModel.refreshTabBar { items, index in
            setTabBarItemsExpectation.fulfill()
            XCTAssertEqual(index, 0)
            XCTAssertEqual(items.map { $0.title }, ["Following", "Following"])
        }
        // Then
        viewModel.fetchReaderMenu()
        waitForExpectations(timeout: 4) { error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
        }
    }

    func testShowTabNoFilter() {
        // Given
        let showTabExpectation = expectation(description: "tab was shown")

        viewModel.setContent = { content in
            showTabExpectation.fulfill()
            XCTAssertNil(content.topic)
        }
        // When
        viewModel.showTab(at: 0)
        // Then
        waitForExpectations(timeout: 4) { error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
        }
    }

    func testShowTabWithFilter() {
        // Given
        let showTabExpectation = expectation(description: "tab was shown")

        let context = MockContext.getContext()!

        let mainTopic = ReaderAbstractTopic(context: context)
        mainTopic.path = "myPath/read/following"
        mainTopic.title = "main topic"

        store .items = [ReaderTabItem(ReaderContent(topic: mainTopic))]

        let filterTopic = ReaderAbstractTopic(context: context)
        filterTopic.title = "I am a test filter topic"

        viewModel.selectedFilter = filterTopic
        viewModel.setContent = { content in
            showTabExpectation.fulfill()
            XCTAssertNotNil(content.topic)
            XCTAssertEqual("I am a test filter topic", content.topic!.title)
        }
        // When
        viewModel.showTab(at: 0)
        // Then
        waitForExpectations(timeout: 4) { error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
        }
    }

    func testSwitchToTabWithTopic() {
        // Given
        let context = MockContext.getContext()!
        switchToTabSetup(context)
        // When
        viewModel.switchToTab(where: {
            ReaderHelpers.topicIsFollowing($0)
        })
        // Then
        waitForExpectations(timeout: 4) { error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
        }
    }

    func testSwitchTabToTitle() {
        // Given
        let context = MockContext.getContext()!
        switchToTabSetup(context)
        // When
        viewModel.switchToTab(where: {
            $0.title == "first topic"
        })
        // Then
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
        viewModel.presentManage(from: controller)
        // Then
        waitForExpectations(timeout: 4) { error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
        }
    }

    func testSettingsTapped() {
        // Given
        let settingsTappedExpectation = expectation(description: "Settings button was tapped")
        viewModel.settingsTapped = { view in
            settingsTappedExpectation.fulfill()
            XCTAssertEqual("test view", view.accessibilityIdentifier!)
        }
        let view = UIView()
        view.accessibilityIdentifier = "test view"
        // When
        viewModel.presentSettings(from: view)
        // Then
        waitForExpectations(timeout: 4) { error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
        }
    }

    func testPresentFilterFromView() {
        // Given
        let filterTappedExpectation = expectation(description: "Filter button was tapped")
        viewModel.filterTapped = { view, completion in
            filterTappedExpectation.fulfill()
        }
        let view = UIView()
        // When
        viewModel.presentFilter(from: view, completion: { title in })
        // Then
        waitForExpectations(timeout: 4) { error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
        }
    }

    func testResetFilter() {
        // Given
        let context = MockContext.getContext()!

        let filterTopic = ReaderAbstractTopic(context: context)
        viewModel.selectedFilter = filterTopic

        let selectedTopic = ReaderAbstractTopic(context: context)
        selectedTopic.title = "selected topic"
        let item = ReaderTabItem(ReaderContent(topic: selectedTopic))

        let setContenttopicExpectation = expectation(description: "content topic was set")
        viewModel.setContent = {
            setContenttopicExpectation.fulfill()
            XCTAssertEqual($0.topic!.title, "selected topic")
        }
        // When
        viewModel.resetFilter(selectedItem: item)
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

        let context = MockContext.getContext()!
        let topic = ReaderAbstractTopic(context: context)
        topic.title = "content topic"
        let content = ReaderContent(topic: topic)
        store.items = [ReaderTabItem(content)]
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

    private func switchToTabSetup(_ context: MockContext) {
        let showTabExpectation = expectation(description: "tab was shown")
        let selectIndexExpectation = expectation(description: "index was selected")

        let topicOne = ReaderAbstractTopic(context: context)
        topicOne.title = "first topic"
        topicOne.path = "myPath/read/following"

        let topicTwo = ReaderAbstractTopic(context: context)
        topicTwo.title = "second topic"

        store.items = [ReaderTabItem(ReaderContent(topic: topicOne)), ReaderTabItem(ReaderContent(topic: topicTwo))]

        viewModel.setContent = { content in
            showTabExpectation.fulfill()
            XCTAssertNotNil(content.topic)
            XCTAssertEqual("first topic", content.topic!.title)
        }
        viewModel.didSelectIndex = { index in
            selectIndexExpectation.fulfill()
            XCTAssertEqual(0, index)
        }
    }
}
