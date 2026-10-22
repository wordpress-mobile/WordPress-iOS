import Combine
import Foundation
import Testing
import UIKit
import WordPressShared

@testable import WordPress
@testable import WordPressData

@MainActor
@Suite("Account avatar owner", .timeLimit(.minutes(1)))
struct AccountAvatarTests {
    private let avatarA = makeImage()
    private let avatarB = makeImage()

    // MARK: - Launch

    @Test("launch with a signed-in account publishes nil, then the image")
    func launchSignedIn() async throws {
        let f = try await Fixture.started(email: "a@example.com")

        #expect(f.fetch.calls == [.init(email: "a@example.com", forceRefresh: false)])
        #expect(f.published.isIdentical(to: [nil]))

        f.fetch.complete(0, with: .success(avatarA))
        try await waitUntil { f.published.count == 2 }
        #expect(f.published.isIdentical(to: [nil, avatarA]))
    }

    @Test("launch with no account publishes nil and never fetches")
    func launchSignedOut() async throws {
        let f = Fixture()
        f.start()

        try await settle()
        #expect(f.fetch.calls.isEmpty)
        #expect(f.published.isIdentical(to: [nil]))
    }

    // MARK: - Account changes

    @Test("account-changed notification with a new account loads it")
    func signInLoadsAccount() async throws {
        let f = Fixture()
        f.start()

        f.signIn(f.addAccount(email: "b@example.com"))
        try await f.fetch.waitForCalls(1)
        #expect(f.fetch.calls == [.init(email: "b@example.com", forceRefresh: false)])

        f.fetch.complete(0, with: .success(avatarB))
        try await waitUntil { f.published.count == 2 }
        #expect(f.published.isIdentical(to: [nil, avatarB]))
    }

    @Test("account removal publishes nil at once and drops the in-flight load")
    func signOutCancelsLoad() async throws {
        let f = try await Fixture.launched(email: "a@example.com", avatar: avatarA)

        f.notifyQuickEditorUpdate(email: "a@example.com")
        try await f.fetch.waitForCalls(2)

        f.signOut()
        #expect(f.published.isIdentical(to: [nil, avatarA, nil]))

        f.fetch.complete(1, with: .success(avatarB))
        try await settle()
        #expect(f.published.isIdentical(to: [nil, avatarA, nil]))
    }

    @Test("signing in after a sign-out loads the new account")
    func signInAfterSignOut() async throws {
        let f = try await Fixture.launched(email: "a@example.com", avatar: avatarA)

        f.signOut()
        f.signIn(f.addAccount(email: "b@example.com"))
        try await f.fetch.waitForCalls(2)
        #expect(f.fetch.calls.last == .init(email: "b@example.com", forceRefresh: false))

        f.fetch.complete(1, with: .success(avatarB))
        try await waitUntil { f.published.count == 4 }
        #expect(f.published.isIdentical(to: [nil, avatarA, nil, avatarB]))
    }

    @Test("token replacement for the same account keeps the avatar")
    func sameAccountNotificationIsIgnored() async throws {
        let f = try await Fixture.launched(email: "a@example.com", avatar: avatarA)

        f.notifyAccountChanged()
        try await settle()
        #expect(f.fetch.calls.count == 1)
        #expect(f.published.isIdentical(to: [nil, avatarA]))
    }

    // MARK: - Main-context changes

    @Test("an account change that keeps the email does not fetch or republish")
    func accountChangeWithSameEmail() async throws {
        let f = try await Fixture.launched(email: "a@example.com", avatar: avatarA)

        f.account?.displayName = "Another Name"
        f.processPendingChanges()
        try await settle()
        #expect(f.fetch.calls.count == 1)
        #expect(f.published.isIdentical(to: [nil, avatarA]))
    }

    @Test("an email change fetches the new email and keeps the old image until it loads")
    func emailChange() async throws {
        let f = try await Fixture.launched(email: "a@example.com", avatar: avatarA)

        f.changeEmail(to: "b@example.com")
        try await f.fetch.waitForCalls(2)
        #expect(f.fetch.calls.last == .init(email: "b@example.com", forceRefresh: false))
        #expect(f.published.isIdentical(to: [nil, avatarA]))

        f.fetch.complete(1, with: .success(avatarB))
        try await waitUntil { f.published.count == 3 }
        #expect(f.published.isIdentical(to: [nil, avatarA, avatarB]))
    }

    @Test("an email saved on a background context fetches the new email")
    func emailChangeMergedFromBackground() async throws {
        let f = try await Fixture.launched(email: "a@example.com", avatar: avatarA)
        let account = try #require(f.account)
        let accountID = TaggedManagedObjectID(account)

        try await f.contextManager.performAndSave { context in
            try context.existingObject(with: accountID).email = "b@example.com"
        }
        try await f.fetch.waitForCalls(2)
        #expect(f.fetch.calls.last == .init(email: "b@example.com", forceRefresh: false))
    }

    @Test("a change that touches no account does not fetch or republish")
    func unrelatedChange() async throws {
        let f = try await Fixture.launched(email: "a@example.com", avatar: avatarA)

        _ = BlogBuilder(f.contextManager.mainContext).build()
        f.processPendingChanges()
        try await settle()
        #expect(f.fetch.calls.count == 1)
        #expect(f.published.isIdentical(to: [nil, avatarA]))
    }

    // MARK: - Quick Editor

    @Test("a Quick Editor update for the account's email forces a reload and keeps the old image until it loads")
    func quickEditorUpdate() async throws {
        let f = try await Fixture.launched(email: "a@example.com", avatar: avatarA)

        f.notifyQuickEditorUpdate(email: "a@example.com")
        try await f.fetch.waitForCalls(2)
        #expect(f.fetch.calls.last == .init(email: "a@example.com", forceRefresh: true))
        #expect(f.published.isIdentical(to: [nil, avatarA]))

        f.fetch.complete(1, with: .success(avatarB))
        try await waitUntil { f.published.count == 3 }
        #expect(f.published.isIdentical(to: [nil, avatarA, avatarB]))
    }

    @Test("a Quick Editor update for another email is ignored")
    func quickEditorUpdateForAnotherEmail() async throws {
        let f = try await Fixture.launched(email: "a@example.com", avatar: avatarA)

        f.notifyQuickEditorUpdate(email: "someone-else@example.com")
        try await settle()
        #expect(f.fetch.calls.count == 1)
        #expect(f.published.isIdentical(to: [nil, avatarA]))
    }

    // MARK: - Failures and retries

    @Test("a failed load keeps the image, and the next account sync retries it")
    func failureThenRecovery() async throws {
        let f = try await Fixture.started(email: "a@example.com")

        f.fetch.complete(0, with: .failure(URLError(.notConnectedToInternet)))
        try await settle()
        #expect(f.published.isIdentical(to: [nil]))

        f.notifyAccountChanged()
        try await f.fetch.waitForCalls(2)
        #expect(f.fetch.calls.last == .init(email: "a@example.com", forceRefresh: false))

        f.fetch.complete(1, with: .success(avatarA))
        try await waitUntil { f.published.count == 2 }
        #expect(f.published.isIdentical(to: [nil, avatarA]))
    }

    @Test("app foreground retries a failed load")
    func foregroundAfterFailure() async throws {
        let f = try await Fixture.started(email: "a@example.com")
        f.fetch.complete(0, with: .failure(URLError(.notConnectedToInternet)))
        try await settle()

        f.notifyForeground()
        try await f.fetch.waitForCalls(2)
        #expect(f.fetch.calls.last == .init(email: "a@example.com", forceRefresh: false))
    }

    @Test("app foreground after a completed load does not fetch")
    func foregroundAfterCompletion() async throws {
        let f = try await Fixture.launched(email: "a@example.com", avatar: avatarA)

        f.notifyForeground()
        try await settle()
        #expect(f.fetch.calls.count == 1)
        #expect(f.published.isIdentical(to: [nil, avatarA]))
    }

    @Test("a failed Quick Editor refresh is retried, forced, on the next foreground")
    func quickEditorRefreshFailureThenRecovery() async throws {
        let f = try await Fixture.launched(email: "a@example.com", avatar: avatarA)

        f.notifyQuickEditorUpdate(email: "a@example.com")
        try await f.fetch.waitForCalls(2)
        f.fetch.complete(1, with: .failure(URLError(.timedOut)))
        try await settle()
        #expect(f.published.isIdentical(to: [nil, avatarA]))

        f.notifyForeground()
        try await f.fetch.waitForCalls(3)
        #expect(f.fetch.calls.last == .init(email: "a@example.com", forceRefresh: true))

        f.fetch.complete(2, with: .success(avatarB))
        try await waitUntil { f.published.count == 3 }
        #expect(f.published.isIdentical(to: [nil, avatarA, avatarB]))

        f.notifyForeground()
        try await settle()
        #expect(f.fetch.calls.count == 3)
    }

    // MARK: - Missing avatars

    @Test("a confirmed missing avatar counts as loaded")
    func missingAvatarCompletes() async throws {
        let f = try await Fixture.started(email: "a@example.com")
        f.fetch.complete(0, with: .success(nil))
        try await settle()
        #expect(f.published.isIdentical(to: [nil]))

        f.notifyAccountChanged()
        f.notifyForeground()
        try await settle()
        #expect(f.fetch.calls.count == 1)
    }

    @Test("an email change to an account without an avatar publishes nil once the load confirms it")
    func emailChangeToMissingAvatar() async throws {
        let f = try await Fixture.launched(email: "a@example.com", avatar: avatarA)

        f.changeEmail(to: "b@example.com")
        try await f.fetch.waitForCalls(2)
        #expect(f.published.isIdentical(to: [nil, avatarA]))

        f.fetch.complete(1, with: .success(nil))
        try await waitUntil { f.published.count == 3 }
        #expect(f.published.isIdentical(to: [nil, avatarA, nil]))
    }

    // MARK: - Ordering

    @Test("a newer load cancels the older one, and only the newer result is published")
    func newerLoadWins() async throws {
        let f = try await Fixture.started(email: "a@example.com")

        f.changeEmail(to: "b@example.com")
        try await f.fetch.waitForCalls(2)

        f.fetch.complete(0, with: .success(avatarA))
        try await settle()
        #expect(f.published.isIdentical(to: [nil]))

        f.fetch.complete(1, with: .success(avatarB))
        try await waitUntil { f.published.count == 2 }
        #expect(f.published.isIdentical(to: [nil, avatarB]))
    }
}

// MARK: - Fixture

@MainActor
private final class Fixture {
    let contextManager = ContextManager.forTesting()
    let notificationCenter = NotificationCenter()
    let fetch = FakeFetch()

    /// Stands in for `UserSettings.defaultDotComUUID`.
    private(set) var defaultUUID: String?
    private(set) var owner: AccountAvatar?
    private(set) var published: [UIImage?] = []
    private var cancellable: AnyCancellable?

    /// The default account in the main context.
    var account: WPAccount? {
        defaultUUID.flatMap { try? WPAccount.lookup(withUUIDString: $0, in: contextManager.mainContext) }
    }

    /// Builds a fixture whose default account has `email` and whose first load
    /// has started.
    static func started(email: String) async throws -> Fixture {
        let f = Fixture()
        f.signIn(f.addAccount(email: email))
        f.start()
        try await f.fetch.waitForCalls(1)
        return f
    }

    /// Builds a fixture whose default account has `email` and whose first load
    /// completed with `avatar`.
    static func launched(email: String, avatar: UIImage) async throws -> Fixture {
        let f = try await started(email: email)
        f.fetch.complete(0, with: .success(avatar))
        try await waitUntil { f.published.count == 2 }
        return f
    }

    func start() {
        processPendingChanges()
        let owner = AccountAvatar(
            coreDataStack: contextManager,
            defaultAccountUUID: { [weak self] in self?.defaultUUID },
            notificationCenter: notificationCenter,
            fetch: { [fetch] email, forceRefresh in
                try await fetch.fetch(email: email, forceRefresh: forceRefresh)
            }
        )
        cancellable = owner.$image.sink { [weak self] in
            self?.published.append($0)
        }
        self.owner = owner
    }

    func addAccount(email: String) -> WPAccount {
        let account = AccountBuilder(contextManager.mainContext).with(username: email).with(email: email).build()
        contextManager.saveContextAndWait(contextManager.mainContext)
        return account
    }

    /// Makes `account` the default and posts the notification, as `AccountService` does.
    func signIn(_ account: WPAccount) {
        defaultUUID = account.uuid
        notifyAccountChanged()
    }

    func signOut() {
        defaultUUID = nil
        notifyAccountChanged()
    }

    func notifyAccountChanged() {
        notificationCenter.post(name: .wpAccountDefaultWordPressComAccountChanged, object: nil)
    }

    func notifyForeground() {
        notificationCenter.post(name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    func notifyQuickEditorUpdate(email: String) {
        notificationCenter.post(
            name: .GravatarQEAvatarUpdateNotification,
            object: nil,
            userInfo: [GravatarQEAvatarUpdateNotificationKeys.email.rawValue: email]
        )
    }

    /// Posts the main context's objects-did-change notification for pending edits.
    func processPendingChanges() {
        contextManager.mainContext.processPendingChanges()
    }

    /// Edits the default account's email on the main context and posts the change.
    func changeEmail(to email: String) {
        account?.email = email
        processPendingChanges()
    }
}

private func makeImage() -> UIImage {
    UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1)).image { _ in }
}

extension Array where Element == UIImage? {
    /// Compares element by element by instance.
    fileprivate func isIdentical(to other: [UIImage?]) -> Bool {
        count == other.count && zip(self, other).allSatisfy { $0 === $1 }
    }
}

/// A fetch that suspends every call until the test completes it.
@MainActor
private final class FakeFetch {
    struct Call: Equatable {
        let email: String
        let forceRefresh: Bool
    }

    private(set) var calls: [Call] = []
    private var pending: [Int: CheckedContinuation<UIImage?, Error>] = [:]

    func fetch(email: String, forceRefresh: Bool) async throws -> UIImage? {
        let index = calls.count
        calls.append(Call(email: email, forceRefresh: forceRefresh))
        return try await withCheckedThrowingContinuation { pending[index] = $0 }
    }

    /// Completes the call at `index`, in the order calls were made.
    func complete(_ index: Int, with result: Result<UIImage?, Error>) {
        pending.removeValue(forKey: index)?.resume(with: result)
    }

    func waitForCalls(_ count: Int) async throws {
        try await waitUntil { calls.count >= count }
    }
}

/// Gives the owner time to act on a trigger that is expected to change nothing.
private func settle() async throws {
    try await Task.sleep(for: .milliseconds(100))
}
