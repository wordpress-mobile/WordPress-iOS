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

        let fetched = try fetch(NotificationsListScope.reader.predicate)

        #expect(Set(fetched) == [notes.newPost, notes.mentionMatch, notes.commentLike])
    }

    @Test func allScopeIncludesEveryKind() throws {
        let notes = try loadNotifications()

        let fetched = try fetch(NotificationsListScope.all.predicate)

        #expect(Set(fetched) == Set(notes.readerRelated + notes.others))
    }

    @Test func readerScopeComposesWithUnreadPredicate() throws {
        let notes = try loadNotifications()
        let unread = NSPredicate(format: "read = NO")

        let fetched = try fetch(
            NSCompoundPredicate(andPredicateWithSubpredicates: [unread, NotificationsListScope.reader.predicate])
        )

        // The `like` fixture is unread too, but not Reader-related.
        #expect(!notes.like.read)
        #expect(Set(fetched) == [notes.newPost, notes.commentLike])
    }

    @Test func readerScopeComposesWithDeletedIDsExclusion() throws {
        let notes = try loadNotifications()
        let notDeleted = NSPredicate(format: "NOT (SELF IN %@)", [notes.newPost.objectID])

        let fetched = try fetch(
            NSCompoundPredicate(andPredicateWithSubpredicates: [notDeleted, NotificationsListScope.reader.predicate])
        )

        #expect(Set(fetched) == [notes.mentionMatch, notes.commentLike])
    }

    @Test func wordPressAppNavigationIsReaderScopedWhenFlagIsOn() {
        #expect(
            NotificationsListScope.forAppNavigation(app: .wordpress, isReaderAndNotificationsEnabled: true) == .reader
        )
        #expect(
            NotificationsListScope.forAppNavigation(app: .wordpress, isReaderAndNotificationsEnabled: false) == .all
        )
    }

    @Test func otherAppsIgnoreFlag() {
        for app in [AppBrand.jetpack, .reader] {
            #expect(NotificationsListScope.forAppNavigation(app: app, isReaderAndNotificationsEnabled: true) == .all)
            #expect(NotificationsListScope.forAppNavigation(app: app, isReaderAndNotificationsEnabled: false) == .all)
        }
    }

    // MARK: - Helpers

    private struct Notes {
        let newPost: WordPressData.Notification
        let mentionMatch: WordPressData.Notification
        let commentLike: WordPressData.Notification
        let comment: WordPressData.Notification
        let like: WordPressData.Notification
        let follow: WordPressData.Notification
        let badge: WordPressData.Notification

        var readerRelated: [WordPressData.Notification] { [newPost, mentionMatch, commentLike] }
        var others: [WordPressData.Notification] { [comment, like, follow, badge] }
    }

    private func loadNotifications() throws -> Notes {
        Notes(
            newPost: try utility.loadNewPostNotification(),
            mentionMatch: try utility.loadMentionMatchNotification(),
            commentLike: try utility.loadCommentLikeNotification(),
            comment: try utility.loadCommentNotification(),
            like: try utility.loadLikeNotification(),
            follow: try utility.loadFollowerNotification(),
            badge: try utility.loadBadgeNotification()
        )
    }

    private func fetch(_ predicate: NSPredicate) throws -> [WordPressData.Notification] {
        let request = NSFetchRequest<WordPressData.Notification>(
            entityName: WordPressData.Notification.classNameWithoutNamespaces()
        )
        request.predicate = predicate
        return try contextManager.mainContext.fetch(request)
    }
}
