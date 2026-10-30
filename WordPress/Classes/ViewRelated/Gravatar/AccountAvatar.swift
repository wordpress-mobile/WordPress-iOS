import UIKit
import AsyncImageKit
import WordPressData

/// The account avatar owner: loads the Gravatar of the default WordPress.com
/// account and publishes it to every place that shows the signed-in person.
///
/// It loads once per email and reloads only when the account or its email
/// changes or the Quick Editor reports an avatar edit. A failed load does not
/// count, so the next account change or app foreground retries it.
@MainActor
final class AccountAvatar: ObservableObject {
    static let shared = AccountAvatar()

    /// Returns the avatar for an email, or `nil` when Gravatar confirms the
    /// email has no avatar. Throws on any other failure.
    typealias Fetch = (_ email: String, _ forceRefresh: Bool) async throws -> UIImage?

    /// The full-size account avatar. `nil` when signed out, when the account has
    /// no avatar, or until the first load completes. The previous image stays
    /// published while a newer load is in flight.
    @Published private(set) var image: UIImage?

    private let coreDataStack: CoreDataStack
    private let defaultAccountUUID: () -> String?
    private let fetch: Fetch

    /// The email of the last load that finished with an image or a confirmed
    /// missing avatar. Never set when a load starts or fails.
    private var completedEmail: String?
    /// The email of a forced refresh that has not succeeded yet. Account syncs
    /// retry it, forced, even though an earlier load for the email completed.
    private var pendingRefreshEmail: String?
    private var inFlight: (email: String, task: Task<Void, Never>)?
    private var observers: [(NotificationCenter, NSObjectProtocol)] = []

    init(
        coreDataStack: CoreDataStack = ContextManager.shared,
        defaultAccountUUID: @escaping () -> String? = { UserSettings.defaultDotComUUID },
        notificationCenter: NotificationCenter = .default,
        fetch: @escaping Fetch = { email, forceRefresh in
            try await ImageDownloader.shared.accountAvatar(for: email, forceRefresh: forceRefresh)
        }
    ) {
        self.coreDataStack = coreDataStack
        self.defaultAccountUUID = defaultAccountUUID
        self.fetch = fetch

        observe(.wpAccountDefaultWordPressComAccountChanged, in: notificationCenter) { owner, _ in
            owner.syncWithDefaultAccount()
        }
        observe(UIApplication.willEnterForegroundNotification, in: notificationCenter) { owner, _ in
            owner.syncWithDefaultAccount()
        }
        // Core Data posts this on the default center regardless of the one injected.
        let mainContext = coreDataStack.mainContext
        observe(.NSManagedObjectContextObjectsDidChange, object: mainContext, in: .default) { owner, notification in
            owner.mainContextObjectsDidChange(notification)
        }

        syncWithDefaultAccount()
    }

    deinit {
        for (center, observer) in observers {
            center.removeObserver(observer)
        }
    }

    /// Reloads the avatar after it was changed on Gravatar, bypassing caches.
    /// Ignored unless `email` is the default account's email. The current image
    /// stays published until the new one arrives.
    func refresh(email: String) {
        guard email == defaultAccountEmail() else {
            return
        }
        pendingRefreshEmail = email
        startLoad(email: email, forceRefresh: true)
    }

    // MARK: - Account sync

    private func syncWithDefaultAccount() {
        guard let email = defaultAccountEmail() else {
            cancelLoad()
            completedEmail = nil
            pendingRefreshEmail = nil
            if image != nil {
                image = nil
            }
            return
        }

        if inFlight?.email == email {
            return
        }
        // A load for another email is stale now, even when this email needs no load.
        cancelLoad()
        if pendingRefreshEmail != email {
            pendingRefreshEmail = nil
        }
        let forceRefresh = pendingRefreshEmail != nil
        if email == completedEmail && !forceRefresh {
            return
        }
        startLoad(email: email, forceRefresh: forceRefresh)
    }

    private func mainContextObjectsDidChange(_ notification: Foundation.Notification) {
        // This fires on every main-context change, so skip the lookup unless an
        // account changed. The email cannot be compared per attribute, because
        // an object merged from a background save is not dirty in the main context.
        let keys = [NSInsertedObjectsKey, NSUpdatedObjectsKey, NSRefreshedObjectsKey, NSDeletedObjectsKey]
        let touchesAccount = keys.contains { key in
            (notification.userInfo?[key] as? Set<NSManagedObject>)?.contains { $0 is WPAccount } ?? false
        }
        if touchesAccount {
            syncWithDefaultAccount()
        }
    }

    private func defaultAccountEmail() -> String? {
        guard let uuid = defaultAccountUUID(), !uuid.isEmpty else {
            return nil
        }
        // Not `WPAccount.lookup(withUUIDString:in:)`: it rewrites `displayName`,
        // which posts another objects-did-change notification and loops forever.
        let predicate = NSPredicate(format: "uuid = %@", uuid)
        guard let email = coreDataStack.mainContext.firstObject(ofType: WPAccount.self, matching: predicate)?.email,
              !email.isEmpty else {
            return nil
        }
        return email
    }

    // MARK: - Loading

    private func startLoad(email: String, forceRefresh: Bool) {
        cancelLoad()
        let fetch = self.fetch
        let task = Task { @MainActor [weak self] in
            let result: Result<UIImage?, Error>
            do {
                result = .success(try await fetch(email, forceRefresh))
            } catch {
                result = .failure(error)
            }
            // A cancelled load was replaced or abandoned, and must not publish.
            guard !Task.isCancelled else {
                return
            }
            self?.finishLoad(email: email, result: result)
        }
        inFlight = (email, task)
    }

    private func finishLoad(email: String, result: Result<UIImage?, Error>) {
        inFlight = nil
        switch result {
        case .success(let image):
            completedEmail = email
            pendingRefreshEmail = nil
            if self.image !== image {
                self.image = image
            }
        case .failure(let error):
            Loggers.app.warning("Failed to load the account avatar: \(error)")
        }
    }

    private func cancelLoad() {
        inFlight?.task.cancel()
        inFlight = nil
    }

    // MARK: - Helpers

    private func observe(
        _ name: Foundation.Notification.Name,
        object: Any? = nil,
        in center: NotificationCenter,
        using handler: @escaping (AccountAvatar, Foundation.Notification) -> Void
    ) {
        let observer = center.addObserver(forName: name, object: object, queue: .main) { [weak self] notification in
            MainActor.assumeIsolated {
                guard let self else { return }
                handler(self, notification)
            }
        }
        observers.append((center, observer))
    }
}
