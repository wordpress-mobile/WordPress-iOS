import BuildSettingsKit
import CoreData
import Testing
import WordPressData

@testable import WordPress

@MainActor
struct NotificationsListScopeTests {
    private let contextManager = ContextManager.forTesting()
    private let utility: NotificationUtility

    init() {
        utility = NotificationUtility(coreDataStack: contextManager)
    }

    @Test func readerScopeIncludesOnlyReaderRelatedKinds() throws {
        let notes = try loadNotifications()

        let fetched = fetch(NotificationsListScope.reader.predicate)

        #expect(Set(fetched) == Set(notes.readerRelated))
    }

    @Test func allScopeIncludesEveryKind() throws {
        let notes = try loadNotifications()

        let fetched = fetch(NotificationsListScope.all.predicate)

        #expect(Set(fetched) == Set(notes.readerRelated + notes.others))
    }

    @Test func onlyTheUnscopedBellShowsNewActivity() async {
        let fixture = await NotificationActivityServiceTests().started(fetch: .success(true))
        #expect(fixture.service.hasNewActivity)

        let unscopedBell = NotificationsButtonViewModel(scope: .all, activityService: fixture.service)
        let readerBell = NotificationsButtonViewModel(scope: .reader, activityService: fixture.service)

        #expect(unscopedBell.hasNewActivity)
        #expect(!readerBell.hasNewActivity)
    }

    // MARK: - Helpers

    private struct Notes {
        let readerRelated: [WordPressData.Notification]
        let others: [WordPressData.Notification]
    }

    private func loadNotifications() throws -> Notes {
        Notes(
            readerRelated: [
                try utility.loadNewPostNotification(),
                try utility.loadMentionMatchNotification(),
                try utility.loadCommentLikeNotification()
            ],
            others: [
                try utility.loadCommentNotification(),
                try utility.loadLikeNotification(),
                try utility.loadFollowerNotification(),
                try utility.loadBadgeNotification()
            ]
        )
    }

    private func fetch(_ predicate: NSPredicate) -> [WordPressData.Notification] {
        contextManager.mainContext.allObjects(ofType: WordPressData.Notification.self, matching: predicate)
    }
}

struct NotificationsListScopeAppNavigationTests {
    @Test(arguments: [
        (AppBrand.wordpress, true, NotificationsListScope.reader),
        (.wordpress, false, .all),
        (.jetpack, true, .all),
        (.jetpack, false, .all),
        (.reader, true, .all),
        (.reader, false, .all)
    ])
    func onlyTheWordPressAppWithTheFlagOnIsReaderScoped(
        app: AppBrand,
        isReaderInWordPressAppEnabled: Bool,
        expected: NotificationsListScope
    ) {
        let scope = NotificationsListScope.forAppNavigation(
            app: app,
            isReaderInWordPressAppEnabled: isReaderInWordPressAppEnabled
        )
        #expect(scope == expected)
    }
}
