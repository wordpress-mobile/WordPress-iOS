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
    }

    override func tearDownWithError() throws {
        controller = nil
        contextManager = nil
        utility = nil
        primerDefaults.restore()
        primerDefaults = nil
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

    // MARK: - Permission primers

    // The primer alert and the inline primer only appear after the system reports an undetermined
    // authorization status, which the test host doesn't control. The second alert has no such
    // dependency, so these tests observe it: showing it resets its counter.

    func testPrimersAreSuppressedOnAppearanceWhenNotificationsAreNotPresented() {
        // Given
        signInToWordPressDotCom()
        controller.notificationMigrationService = makeMigrationService(shouldPresentNotifications: false)
        controller.loadViewIfNeeded()

        // First appearance, then a repeated appearance past the inline prompt threshold.
        for tabAccessCount in [1, 6] {
            PrimerDefaults.fresh.restore()
            userDefaults.notificationsTabAccessCount = tabAccessCount
            userDefaults.secondNotificationsAlertCount = Constants.secondAlertThreshold

            // When
            controller.showNotificationPrimersIfNeeded()

            // Then
            XCTAssertEqual(userDefaults.secondNotificationsAlertCount, Constants.secondAlertThreshold)
        }
    }

    func testPrimersAppearOnAppearanceWhenNotificationsArePresented() {
        // Given
        signInToWordPressDotCom()
        controller.notificationMigrationService = makeMigrationService(shouldPresentNotifications: true)
        controller.loadViewIfNeeded()

        for tabAccessCount in [1, 6] {
            PrimerDefaults.fresh.restore()
            userDefaults.notificationsTabAccessCount = tabAccessCount
            userDefaults.secondNotificationsAlertCount = Constants.secondAlertThreshold

            // When
            controller.showNotificationPrimersIfNeeded()

            // Then
            XCTAssertEqual(userDefaults.secondNotificationsAlertCount, Constants.secondAlertDisabled)
        }
    }

    func testSecondAlertIsSuppressedAfterSyncWhenNotificationsAreNotPresented() {
        // Given
        let window = showControllerAfterSync(shouldPresentNotifications: false)

        // When
        controller.tableViewDidChangeContent(controller.tableView)

        // Then
        XCTAssertEqual(userDefaults.secondNotificationsAlertCount, Constants.secondAlertThreshold)
        window.isHidden = true
    }

    func testSecondAlertAppearsAfterSyncWhenNotificationsArePresented() {
        // Given
        let window = showControllerAfterSync(shouldPresentNotifications: true)

        // When
        controller.tableViewDidChangeContent(controller.tableView)

        // Then
        XCTAssertEqual(userDefaults.secondNotificationsAlertCount, Constants.secondAlertDisabled)
        window.isHidden = true
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

    func fetchNotifications(matching predicate: NSPredicate) throws -> [WordPressData.Notification] {
        let request = NSFetchRequest<WordPressData.Notification>(entityName: Constants.entityName)
        request.predicate = predicate
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        return try contextManager.mainContext.fetch(request)
    }

    func makeMigrationService(shouldPresentNotifications: Bool) -> JetpackNotificationMigrationServiceMock {
        let service = JetpackNotificationMigrationServiceMock()
        service.shouldPresentNotificationsToReturn = shouldPresentNotifications
        return service
    }

    /// Puts the list on screen with the second alert due, as it is when a sync adds notifications.
    func showControllerAfterSync(shouldPresentNotifications: Bool) -> UIWindow {
        signInToWordPressDotCom()
        PrimerDefaults.fresh.restore()
        userDefaults.notificationPrimerInlineWasAcknowledged = true
        userDefaults.secondNotificationsAlertCount = Constants.secondAlertThreshold
        controller.notificationMigrationService = makeMigrationService(
            shouldPresentNotifications: shouldPresentNotifications
        )
        controller.loadViewIfNeeded()

        let window = UIWindow()
        window.rootViewController = controller
        window.isHidden = false
        return window
    }

    var notificationCount: Int? {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: Constants.entityName)
        return try? contextManager.mainContext.count(for: request)
    }

    func postAccountChangeNotification() {
        NotificationCenter.default.post(name: .wpAccountDefaultWordPressComAccountChanged, object: nil)
    }
}
