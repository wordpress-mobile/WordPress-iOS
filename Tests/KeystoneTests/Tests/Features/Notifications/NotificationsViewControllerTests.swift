import XCTest
import OHHTTPStubs
import OHHTTPStubsSwift
@testable import WordPress
@testable import WordPressData

final class NotificationsViewControllerTests: XCTestCase {

    private var controller: NotificationsViewController!
    private var contextManager: ContextManager!
    private var utility: NotificationUtility!

    override func setUpWithError() throws {
        contextManager = ContextManager.forTesting()
        contextManager.useAsSharedInstance(untilTestFinished: self)
        utility = NotificationUtility(coreDataStack: contextManager)
        controller = NotificationsViewController.loadFromStoryboard()
    }

    override func tearDownWithError() throws {
        controller = nil
        contextManager = nil
        utility = nil
        UserSettings.defaultDotComUUID = nil
        HTTPStubs.removeAllStubs()
        FeatureFlagOverrideStore().removeOverride(for: FeatureFlag.readerAndNotificationsInWordPressApp)
    }

    func testResetNotificationsWhenAccountChange() throws {
        // Give
        _ = try utility.loadBadgeNotification()

        // When
        postAccountChangeNotification()

        // Then
        XCTAssertEqual(notificationCount, 0)
    }

    func testNeedsReloadResultsWhenAccountChange() throws {
        // Give
        controller.needsReloadResults = false

        // When
        postAccountChangeNotification()

        // Then
        XCTAssertEqual(controller.needsReloadResults, true)
    }

    @MainActor
    func testSubmitsSeenForNotificationOutsideSelectedFilter() async throws {
        // Given a visible list filtered to comments
        let uuid = "account-A"
        AccountBuilder(contextManager.mainContext).with(uuid: uuid).build()
        let previousDefaultDotComUUID = UserSettings.defaultDotComUUID
        UserSettings.defaultDotComUUID = uuid
        addTeardownBlock { UserSettings.defaultDotComUUID = previousDefaultDotComUUID }

        let serviceTests = NotificationActivityServiceTests()
        let fixture = await serviceTests.started(uuid: uuid)
        controller = NotificationsViewController.loadFromStoryboard()
        controller.activityService = fixture.service

        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = controller
        window.makeKeyAndVisible()
        addTeardownBlock { window.isHidden = true }

        controller.filterTabBar.setSelectedIndex(2)
        controller.filterTabBar.sendActions(for: .valueChanged)

        // When a like arrives
        _ = try utility.loadLikeNotification()
        contextManager.mainContext.processPendingChanges()
        await serviceTests.settle(fixture)

        // Then
        // The fixture's timestamp, 2015-03-28T00:23:41+00:00, in Unix seconds.
        XCTAssertEqual(fixture.remote.seenTimestamps, [Date(timeIntervalSince1970: 1_427_502_221)])
    }

    // MARK: - Reader scope

    func testReaderScopeShowsAllAndUnreadFilters() {
        // Given
        controller.scope = .reader

        // When
        controller.loadViewIfNeeded()

        // Then
        XCTAssertEqual(controller.filterTabBar.items.map(\.title), ["All", "Unread"])
    }

    func testAllScopeShowsEveryFilter() {
        // When
        controller.loadViewIfNeeded()

        // Then
        XCTAssertEqual(controller.filterTabBar.items.count, 5)
    }

    func testReaderScopeMenuOffersMarkAllAsReadOnly() throws {
        // Given
        signInToWordPressDotCom()
        _ = try utility.loadNewPostNotification()
        controller.scope = .reader

        // When
        controller.loadViewIfNeeded()

        // Then
        XCTAssertEqual(controller.makeMoreMenuElements().map(\.title), ["Mark All As Read"])
    }

    func testAllScopeMenuOffersMarkAllAsReadAndSettings() throws {
        // Given
        signInToWordPressDotCom()
        _ = try utility.loadNewPostNotification()

        // When
        controller.loadViewIfNeeded()

        // Then
        XCTAssertEqual(controller.makeMoreMenuElements().map(\.title), ["Mark All As Read", "Notification Settings"])
    }

    func testReaderScopeUnreadFilterShowsUnreadReaderNotifications() throws {
        // Given
        let newPost = try utility.loadNewPostNotification() // unread
        _ = try utility.loadMentionMatchNotification() // read
        let commentLike = try utility.loadCommentLikeNotification() // unread
        _ = try utility.loadLikeNotification() // unread, not Reader-related
        controller.scope = .reader
        controller.loadViewIfNeeded()

        // When
        controller.filterTabBar.setSelectedIndex(1)
        controller.selectedFilterDidChange(controller.filterTabBar)

        // Then
        XCTAssertEqual(try fetchNotifications(matching: controller.predicateForFetchRequest()), [newPost, commentLike])
    }

    func testReaderScopeMarkAllAsReadMarksOnlyReaderNotifications() throws {
        // Given
        signInToWordPressDotCom()
        stub(condition: isHost("public-api.wordpress.com")) { _ in
            HTTPStubsResponse(jsonObject: ["success": true], statusCode: 200, headers: nil)
        }
        let newPost = try utility.loadNewPostNotification()
        let like = try utility.loadLikeNotification()
        XCTAssertFalse(newPost.read)
        XCTAssertFalse(like.read)
        controller.scope = .reader
        controller.loadViewIfNeeded()

        // When
        controller.markAllAsRead()

        // Then
        let isNewPostRead = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in newPost.read }, object: nil)
        wait(for: [isNewPostRead], timeout: 2)
        XCTAssertFalse(like.read)
    }

    func testAppNavigationListsAreReaderScopedWhenFlagIsOn() {
        // Given
        FeatureFlagOverrideStore().override(FeatureFlag.readerAndNotificationsInWordPressApp, withValue: true)

        // Then
        XCTAssertEqual(NotificationsViewController.makeForAppNavigation().scope, .reader)
        XCTAssertEqual(NotificationsSplitViewContent().notificationsViewController.scope, .reader)
        XCTAssertEqual(WPTabBarController(staticScreens: false).notificationsViewController?.scope, .reader)
    }

    func testAppNavigationListsAreUnscopedWhenFlagIsOff() {
        // Given
        FeatureFlagOverrideStore().override(FeatureFlag.readerAndNotificationsInWordPressApp, withValue: false)

        // Then
        XCTAssertEqual(NotificationsViewController.makeForAppNavigation().scope, .all)
        XCTAssertEqual(NotificationsSplitViewContent().notificationsViewController.scope, .all)
        XCTAssertEqual(WPTabBarController(staticScreens: false).notificationsViewController?.scope, .all)
    }
}

private extension NotificationsViewControllerTests {

    enum Constants {
        static let entityName = "Notification"
    }

    func signInToWordPressDotCom() {
        let account = AccountBuilder(contextManager.mainContext)
            .with(username: "NotificationsViewControllerTests")
            .with(authToken: "token")
            .build()
        UserSettings.defaultDotComUUID = account.uuid
    }

    func fetchNotifications(matching predicate: NSPredicate) throws -> [WordPressData.Notification] {
        let request = NSFetchRequest<WordPressData.Notification>(entityName: Constants.entityName)
        request.predicate = predicate
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        return try contextManager.mainContext.fetch(request)
    }

    var notificationCount: Int? {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: Constants.entityName)
        return try? contextManager.mainContext.count(for: request)
    }

    func postAccountChangeNotification() {
        NotificationCenter.default.post(name: .wpAccountDefaultWordPressComAccountChanged, object: nil)
    }
}
