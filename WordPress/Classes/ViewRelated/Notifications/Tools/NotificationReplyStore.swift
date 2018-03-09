import Foundation


// MARK: - NotificationReplyStore
//
class NotificationReplyStore {

    /// Shared Instance.
    ///
    static let shared = NotificationReplyStore()

    /// Unit Testing Helper: Allows us to hack the current date.
    ///
    private var overridenNow: Date?

    /// Our beautiful and private Initializer. In here we'll trigger the cleanup sequence, which removes outdated replies!.
    ///
    private init() {
        purgeOldReplies()
    }

    /// Unit Testing Helper: Allows us to hack the current date.
    ///
    init(now: Date) {
        overridenNow = now
        purgeOldReplies(now: now)
    }


    /// Retrieves the cached reply, for the specified notificationID (if any).
    ///
    func loadReply(for notificationID: String) -> String? {
        return replies[notificationID]
    }

    /// Stores a given reply, for the specified notificationID.
    ///
    func store(reply: String, for notificationID: String) {
        replies[notificationID] = reply
        timestamps[notificationID] = overridenNow?.normalizedDate() ?? Date().normalizedDate()
    }

    /// Meant for unit testing purposes. Effectively nukes the cached replies.
    ///
    func reset() {
        replies = [:]
        timestamps = [:]
    }
}


// MARK: - Private Methods
//
private extension NotificationReplyStore {

    /// Nukes entries older than `Settings.timeToLiveInDays`.
    ///
    func purgeOldReplies(now: Date = Date()) {
        guard let expiredKeys = findExpiredKeys(inRelationTo: now) else {
            return
        }

        removeEntries(with: expiredKeys)
    }

    /// Returns the collection of expired keys, when compared to the specified Date.
    ///
    private func findExpiredKeys(inRelationTo now: Date) -> Set<String>? {
        var expiredKeys = Set<String>()
        for (key, timestamp) in timestamps where deltaInDays(between: now, and: timestamp) > Settings.timeToLiveInDays {
            expiredKeys.insert(key)
        }

        return expiredKeys.isEmpty ? nil : expiredKeys
    }

    /// Returns the difference, in days, between the two specified dates.
    ///
    private func deltaInDays(between lhs: Date, and rhs: Date) -> Int {
        return Calendar.current.dateComponents([.day], from: lhs, to: rhs).day ?? .min
    }

    /// Removes the specified collection of Keys.
    ///
    private func removeEntries(with keys: Set<String>) {
        replies = replies.filter { keys.contains($0.key) == false }
        timestamps = timestamps.filter { keys.contains($0.key) == false }
    }
}


// MARK: - Private Calculated Properties
//
private extension NotificationReplyStore {

    /// Returns the Replies Dictionary.
    ///
    var replies: [String: String] {
        get {
            let replies = UserDefaults.standard.dictionary(forKey: Settings.contentsKey) as? [String: String]
            return replies ?? [String: String]()
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Settings.contentsKey)
        }
    }

    /// Returns the Timestamps Dictionary.
    ///
    var timestamps: [String: Date] {
        get {
            let timestamps = UserDefaults.standard.dictionary(forKey: Settings.timestampsKey) as? [String: Date]
            return timestamps ?? [String: Date]()
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Settings.timestampsKey)
        }
    }
}


// MARK: - Private Structures
//
private extension NotificationReplyStore {

    /// Settings
    ///
    enum Settings {
        static let contentsKey = "NotificationsReplyContents"
        static let timestampsKey = "NotificationsReplyTimestamps"
        static let timeToLiveInDays = 7
    }
}
