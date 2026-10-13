import Foundation
import WordPressShared

/// Persisted snapshot of a single account's Notifications bell state.
///
/// Only the active account's snapshot is kept. A snapshot restores at launch
/// only when its `accountUUID` matches the current default account.
struct NotificationActivitySnapshot: Codable, Equatable {
    /// Stable UUID of the account this snapshot belongs to.
    var accountUUID: String
    /// Last known bell state.
    var hasActivity: Bool
    /// Newest timestamp the backend has acknowledged as seen.
    var acknowledgedSeen: Date?
    /// Newest timestamp whose seen write has not yet succeeded.
    var pendingSeen: Date?
}

/// Stores the snapshot as JSON under a single key in ordinary app storage, not
/// the shared-extension store: the in-app bell is an app-only concern.
final class NotificationActivityStore {
    private let repository: UserPersistentRepository
    private let key = "notifications_activity_state"

    init(repository: UserPersistentRepository = UserPersistentStoreFactory.instance()) {
        self.repository = repository
    }

    func load() -> NotificationActivitySnapshot? {
        guard let json = repository.string(forKey: key),
            let data = json.data(using: .utf8)
        else {
            return nil
        }
        return try? JSONDecoder().decode(NotificationActivitySnapshot.self, from: data)
    }

    func save(_ snapshot: NotificationActivitySnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot),
            let json = String(data: data, encoding: .utf8)
        else {
            return
        }
        repository.set(json, forKey: key)
    }

    func clear() {
        repository.removeObject(forKey: key)
    }
}
