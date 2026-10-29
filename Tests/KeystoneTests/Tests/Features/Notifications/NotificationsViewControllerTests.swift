import XCTest
import OHHTTPStubs
import OHHTTPStubsSwift
import WordPressShared
@testable import WordPress
@testable import WordPressData

final class NotificationsViewControllerTests: XCTestCase {

    private var controller: NotificationsViewController!
    private var contextManager: ContextManager!
    private var utility: NotificationUtility!
    private var primerDefaults: PrimerDefaults!

    override func setUpWithError() throws {
        contextManager = ContextManager.forTesting()
        contextManager.useAsSharedInstance(untilTestFinished: self)
        utility = NotificationUtility(coreDataStack: contextManager)
        controller = NotificationsViewController.loadFromStoryboard()
        primerDefaults = PrimerDefaults.current
        stub(condition: isHost("public-api.wordpress.com")) { _ in
            HTTPStubsResponse(jsonObject: ["success": true], statusCode: 200, headers: nil)
        }
    }

    override func tearDownWithError() throws {
        controller = nil
        contextManager = nil
        utility = nil
        primerDefaults.restore()
        primerDefaults = nil
        UserSettings.defaultDotComUUID = nil
        HTTPStubs.removeAllStubs()
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
        XCTAssertEqual(fetchNotifications(matching: controller.predicateForFetchRequest()), [newPost, commentLike])
    }

    func testReaderScopeMarkAllAsReadMarksOnlyReaderNotifications() throws {
        // Given
        signInToWordPressDotCom()
        let newPost = try utility.loadNewPostNotification()
        let like = try utility.loadLikeNotification()
        XCTAssertFalse(newPost.read)
        XCTAssertFalse(like.read)
        controller.scope = .reader
        controller.loadViewIfNeeded()

        // When
        controller.markAllAsRead()

        // Then
        let isNewPostRead = keyValueObservingExpectation(for: newPost, keyPath: "read", expectedValue: true)
        wait(for: [isNewPostRead], timeout: 2)
        XCTAssertFalse(like.read)
    }

    func testAppNavigationListsAreReaderScopedWhenFlagIsOn() {
        // Given
        let wasReaderInWordPressAppEnabled = JetpackFeaturesRemovalCoordinator.isReaderInWordPressAppEnabled
        JetpackFeaturesRemovalCoordinator.isReaderInWordPressAppEnabled = true
        addTeardownBlock {
            JetpackFeaturesRemovalCoordinator.isReaderInWordPressAppEnabled = wasReaderInWordPressAppEnabled
        }

        // Then
        XCTAssertEqual(NotificationsViewController.makeForAppNavigation().scope, .reader)
        XCTAssertEqual(NotificationsSplitViewContent().notificationsViewController.scope, .reader)
        XCTAssertEqual(WPTabBarController(staticScreens: false).notificationsViewController?.scope, .reader)
    }

    func testReaderScopedListRegistersNoSpotlightActivity() {
        // Given
        controller.scope = .reader

        // When
        showController()

        // Then
        XCTAssertNil(controller.userActivity)
    }

    func testUnscopedListRegistersTheNotificationsSpotlightActivity() throws {
        // When
        showController()

        // Then
        let activity = try XCTUnwrap(controller.userActivity)
        XCTAssertEqual(activity.activityType, WPActivityType.notifications.rawValue)
        XCTAssertTrue(activity.isEligibleForSearch)
    }

    func testPushedListKeepsTheLargeTitlesOfTheNavigationBar() {
        // Given a navigation stack whose screens use large titles, as Reader's does
        let navigationController = UINavigationController(rootViewController: UIViewController())
        navigationController.navigationBar.prefersLargeTitles = true
        let list = NotificationsViewController.makeForAppNavigation()

        // When
        navigationController.pushViewController(list, animated: false)
        list.loadViewIfNeeded()

        // Then the list uses an inline title without changing the bar
        XCTAssertTrue(navigationController.navigationBar.prefersLargeTitles)
        XCTAssertEqual(list.navigationItem.largeTitleDisplayMode, .never)
        XCTAssertEqual(list.navigationItem.title, "Notifications")
    }

    @MainActor
    func testReaderScopedListSubmitsNoSeen() async throws {
        let seenTimestamps = try await seenTimestampsWhileShowingList(scope: .reader)

        XCTAssertEqual(seenTimestamps, [])
    }

    @MainActor
    func testUnscopedListSubmitsSeen() async throws {
        let seenTimestamps = try await seenTimestampsWhileShowingList(scope: .all)

        // The fixtures' timestamps in Unix seconds: the new post, 2015-03-31T10:00:00+00:00,
        // submitted when the list appears, then the comment like, 2015-03-31T12:00:00+00:00.
        XCTAssertEqual(
            seenTimestamps,
            [Date(timeIntervalSince1970: 1_427_796_000), Date(timeIntervalSince1970: 1_427_803_200)]
        )
    }

    /// Shows a list with `scope` that has a Reader notification, then stores a newer Reader
    /// notification while the list is visible. Returns the timestamps the list submitted as seen.
    @MainActor
    private func seenTimestampsWhileShowingList(scope: NotificationsListScope) async throws -> [Date] {
        let uuid = "account-A"
        AccountBuilder(contextManager.mainContext).with(uuid: uuid).build()
        let previousDefaultDotComUUID = UserSettings.defaultDotComUUID
        UserSettings.defaultDotComUUID = uuid
        addTeardownBlock { UserSettings.defaultDotComUUID = previousDefaultDotComUUID }

        let serviceTests = NotificationActivityServiceTests()
        let fixture = await serviceTests.started(uuid: uuid)
        _ = try utility.loadNewPostNotification()
        controller = NotificationsViewController.loadFromStoryboard()
        controller.activityService = fixture.service
        controller.scope = scope

        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = controller
        window.makeKeyAndVisible()
        addTeardownBlock { window.isHidden = true }

        _ = try utility.loadCommentLikeNotification()
        contextManager.mainContext.processPendingChanges()
        await serviceTests.settle(fixture)

        // The list can outlive the test. With notifications still in it, resetting the test's
        // Core Data stack trips the "Notification Timestamp should not be nil" assertion.
        contextManager.mainContext.deleteAllObjects(ofType: WordPressData.Notification.self)
        contextManager.mainContext.processPendingChanges()

        return fixture.remote.seenTimestamps
    }

    // MARK: - Permission primers

    // The primer alert and the inline primer only appear after the system reports an undetermined
    // authorization status, which the test host doesn't control. The second alert has no such
    // dependency, so these tests observe it: when it is due, it resets its counter.

    func testSecondAlertIsSuppressedOnAppearanceWhenNotificationsAreNotPresented() {
        // Given
        makeSecondAlertDue(shouldPresentNotifications: false)

        // When
        controller.showNotificationPrimersIfNeeded()

        // Then
        XCTAssertEqual(userDefaults.secondNotificationsAlertCount, Constants.secondAlertThreshold)
    }

    func testSecondAlertIsConsumedOnAppearanceWhenNotificationsArePresented() {
        // Given
        makeSecondAlertDue(shouldPresentNotifications: true)

        // When
        controller.showNotificationPrimersIfNeeded()

        // Then
        XCTAssertEqual(userDefaults.secondNotificationsAlertCount, Constants.secondAlertDisabled)
    }

    func testSecondAlertIsSuppressedAfterSyncWhenNotificationsAreNotPresented() {
        // Given
        makeSecondAlertDue(shouldPresentNotifications: false)
        showControllerInWindow()

        // When
        controller.tableViewDidChangeContent(controller.tableView)

        // Then
        XCTAssertEqual(userDefaults.secondNotificationsAlertCount, Constants.secondAlertThreshold)
    }

    func testSecondAlertIsConsumedAfterSyncWhenNotificationsArePresented() {
        // Given
        makeSecondAlertDue(shouldPresentNotifications: true)
        showControllerInWindow()

        // When
        controller.tableViewDidChangeContent(controller.tableView)

        // Then
        XCTAssertEqual(userDefaults.secondNotificationsAlertCount, Constants.secondAlertDisabled)
    }
}

private extension NotificationsViewControllerTests {

    enum Constants {
        static let entityName = "Notification"
        static let secondAlertThreshold = 10
        static let secondAlertDisabled = -1
    }

    /// The permission primers read their state from the standard user defaults, so tests save and restore it.
    struct PrimerDefaults {
        var onboardingNotificationsPromptDisplayed: Bool
        var notificationPrimerAlertWasDisplayed: Bool
        var notificationPrimerInlineWasAcknowledged: Bool
        var notificationsTabAccessCount: Int
        var secondNotificationsAlertCount: Int

        static var current: PrimerDefaults {
            let userDefaults = UserPersistentStoreFactory.instance()
            return PrimerDefaults(
                onboardingNotificationsPromptDisplayed: userDefaults.onboardingNotificationsPromptDisplayed,
                notificationPrimerAlertWasDisplayed: userDefaults.notificationPrimerAlertWasDisplayed,
                notificationPrimerInlineWasAcknowledged: userDefaults.notificationPrimerInlineWasAcknowledged,
                notificationsTabAccessCount: userDefaults.notificationsTabAccessCount,
                secondNotificationsAlertCount: userDefaults.secondNotificationsAlertCount
            )
        }

        static let fresh = PrimerDefaults(
            onboardingNotificationsPromptDisplayed: false,
            notificationPrimerAlertWasDisplayed: false,
            notificationPrimerInlineWasAcknowledged: false,
            notificationsTabAccessCount: 0,
            secondNotificationsAlertCount: 0
        )

        func restore() {
            let userDefaults = UserPersistentStoreFactory.instance()
            userDefaults.onboardingNotificationsPromptDisplayed = onboardingNotificationsPromptDisplayed
            userDefaults.notificationPrimerAlertWasDisplayed = notificationPrimerAlertWasDisplayed
            userDefaults.notificationPrimerInlineWasAcknowledged = notificationPrimerInlineWasAcknowledged
            userDefaults.notificationsTabAccessCount = notificationsTabAccessCount
            userDefaults.secondNotificationsAlertCount = secondNotificationsAlertCount
        }
    }

    var userDefaults: UserPersistentRepository {
        UserPersistentStoreFactory.instance()
    }

    func signInToWordPressDotCom() {
        let account = AccountBuilder(contextManager.mainContext)
            .with(username: "NotificationsViewControllerTests")
            .with(authToken: "token")
            .build()
        UserSettings.defaultDotComUUID = account.uuid
    }

    func fetchNotifications(matching predicate: NSPredicate) -> [WordPressData.Notification] {
        contextManager.mainContext.allObjects(
            ofType: WordPressData.Notification.self,
            matching: predicate,
            sortedBy: [NSSortDescriptor(key: "timestamp", ascending: true)]
        )
    }

    func makeMigrationService(shouldPresentNotifications: Bool) -> JetpackNotificationMigrationServiceMock {
        let service = JetpackNotificationMigrationServiceMock()
        service.shouldPresentNotificationsToReturn = shouldPresentNotifications
        return service
    }

    /// Runs the controller's appearance callbacks without the permission primers.
    func showController() {
        signInToWordPressDotCom()
        controller.notificationMigrationService = makeMigrationService(shouldPresentNotifications: false)
        controller.loadViewIfNeeded()
        controller.beginAppearanceTransition(true, animated: false)
        controller.endAppearanceTransition()
    }

    /// Signs in and makes the second alert due, as it is after a sync adds notifications. The
    /// acknowledged inline primer keeps the primer alert from scheduling itself.
    func makeSecondAlertDue(shouldPresentNotifications: Bool) {
        signInToWordPressDotCom()
        PrimerDefaults.fresh.restore()
        userDefaults.notificationPrimerInlineWasAcknowledged = true
        userDefaults.secondNotificationsAlertCount = Constants.secondAlertThreshold
        controller.notificationMigrationService = makeMigrationService(
            shouldPresentNotifications: shouldPresentNotifications
        )
        controller.loadViewIfNeeded()
    }

    /// Puts the list on screen, which the second alert requires after a sync.
    func showControllerInWindow() {
        let window = UIWindow()
        window.rootViewController = controller
        window.isHidden = false
        addTeardownBlock { window.isHidden = true }
    }

    var notificationCount: Int? {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: Constants.entityName)
        return try? contextManager.mainContext.count(for: request)
    }

    func postAccountChangeNotification() {
        NotificationCenter.default.post(name: .wpAccountDefaultWordPressComAccountChanged, object: nil)
    }
}
