import UIKit
import XCTest

@testable import WordPress
@testable import WordPressData

final class ReaderPresenterTests: CoreDataTestCase {
    private var previousDefaultDotComUUID: String?
    private var previousSidebarSelection: ReaderStaticScreen?

    override func setUp() {
        super.setUp()
        contextManager.useAsSharedInstance(untilTestFinished: self)

        previousDefaultDotComUUID = UserSettings.defaultDotComUUID
        previousSidebarSelection = UserDefaults.standard.readerSidebarSelection

        let account = AccountBuilder(mainContext)
            .with(username: "reader-user")
            .with(authToken: "reader-token")
            .build()
        UserSettings.defaultDotComUUID = account.uuid

        let discover = ReaderDefaultTopic(context: mainContext)
        discover.path = "https://public-api.wordpress.com/rest/v1.2/read/sites/53424024/posts"
        discover.title = "Discover"
        discover.type = ReaderDefaultTopic.TopicType
        discover.showInMenu = true

        let following = ReaderDefaultTopic(context: mainContext)
        following.path = "https://public-api.wordpress.com/rest/v1.2/read/following"
        following.title = "Recent"
        following.type = ReaderDefaultTopic.TopicType
        following.showInMenu = true
        contextManager.saveContextAndWait(mainContext)

        UserDefaults.standard.readerSidebarSelection = .discover
    }

    override func tearDown() {
        UserSettings.defaultDotComUUID = previousDefaultDotComUUID
        UserDefaults.standard.readerSidebarSelection = previousSidebarSelection
        super.tearDown()
    }

    @MainActor
    func testSavedFeedIsUnderADeepLinkedPost() {
        let presenter = makePresenter()
        let navigationController = presenter.prepareForTabBarPresentation()

        presenter.navigate(to: .post(postID: 1, siteID: 2, isFeed: false), animated: false)

        let stack = navigationController.viewControllers
        XCTAssertEqual(stack.count, 3)
        XCTAssertTrue(stack.dropFirst().first is ReaderDiscoverViewController)
        XCTAssertTrue(stack.last is ReaderDetailViewController)

        navigationController.popViewController(animated: false)
        XCTAssertTrue(navigationController.topViewController === stack[1])
        navigationController.popToRootViewController(animated: false)
        presenter.sidebar.loadViewIfNeeded()
        XCTAssertEqual(navigationController.viewControllers.count, 1)
        XCTAssertTrue(navigationController.topViewController === presenter.sidebar)
    }

    @MainActor
    func testOpeningTheSavedFeedAgainDoesNotPushItTwice() {
        let presenter = makePresenter()
        let navigationController = presenter.prepareForTabBarPresentation()

        presenter.navigate(to: .discover, animated: false)

        XCTAssertEqual(navigationController.viewControllers.count, 2)
        XCTAssertTrue(navigationController.topViewController is ReaderDiscoverViewController)
    }

    @MainActor
    func testSwitchingFeedsPreservesTheSavedFeed() {
        let presenter = makePresenter()
        let navigationController = presenter.prepareForTabBarPresentation()

        let savedFeed = navigationController.topViewController
        presenter.navigate(to: .recent, animated: false)

        XCTAssertEqual(navigationController.viewControllers.count, 3)
        XCTAssertTrue(navigationController.topViewController is ReaderStreamViewController)
        XCTAssertTrue(navigationController.viewControllers[1] === savedFeed)
        navigationController.popViewController(animated: false)
        XCTAssertTrue(navigationController.topViewController === savedFeed)
    }

    @MainActor
    func testBackFromADeepLinkedTagReturnsToTheSavedFeed() {
        let presenter = makePresenter()
        let navigationController = presenter.prepareForTabBarPresentation()

        let savedFeed = navigationController.topViewController
        presenter.navigate(to: .tag("photography"), animated: false)

        XCTAssertEqual(navigationController.viewControllers.count, 3)
        XCTAssertTrue(navigationController.topViewController is ReaderStreamViewController)
        XCTAssertTrue(navigationController.viewControllers[1] === savedFeed)
        navigationController.popViewController(animated: false)
        XCTAssertTrue(navigationController.topViewController === savedFeed)
    }

    @MainActor
    func testDiscoverDedupePreservesExistingFeedAndController() {
        UserDefaults.standard.readerSidebarSelection = .recent
        let presenter = makePresenter()
        let navigationController = presenter.prepareForTabBarPresentation()
        let recent = navigationController.topViewController
        XCTAssertTrue(recent is ReaderStreamViewController)

        presenter.navigate(to: .discover, animated: false)
        let discover = navigationController.topViewController
        XCTAssertTrue(discover is ReaderDiscoverViewController)
        XCTAssertEqual(navigationController.viewControllers.count, 3)
        XCTAssertTrue(navigationController.viewControllers[1] === recent)

        presenter.navigate(to: .discover, animated: false)
        XCTAssertEqual(navigationController.viewControllers.count, 3)
        XCTAssertTrue(navigationController.topViewController === discover)
        XCTAssertTrue(navigationController.viewControllers[1] === recent)
    }

    @MainActor
    private func makePresenter() -> ReaderPresenter {
        ReaderPresenter(
            viewModel: ReaderSidebarViewModel(menuStore: MockReaderMenuStore(), contextManager: contextManager)
        )
    }
}

private struct MockReaderMenuStore: ReaderMenuStoreProtocol {
    func refreshMenu() {}
}
