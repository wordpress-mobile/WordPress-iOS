import Foundation

/// A struct that returns the Reader CSS URL
/// If you need to fix an issue in the CSS, see pbArwn-GU-p2
///
struct ReaderCSS {
    private let store: KeyValueDatabase

    private let now: Int

    private let isInternetReachable: () -> Bool

    private let expirationDays: Int = 5

    private var expirationDaysInSeconds: Int {
        return expirationDays * 60 * 60 * 24
    }

    static let updatedKey = "ReaderCSSLastUpdated"

    /// Returns a custom Reader CSS URL
    /// This value can be changed under Settings > Debug
    ///
    var customAddress: String? {
        get {
            return store.object(forKey: "reader-css-url") as? String
        }
        set {
            store.set(newValue, forKey: "reader-css-url")
        }
    }

    /// Returns the Reader CSS appending a timestamp
    /// We force it to update based on the `expirationDays` property
    ///
    var address: String {
        // Always returns a fresh CSS if the flag is enabled
        guard !FeatureFlag.readerCSS.enabled else {
            return url(appendingTimestamp: now)
        }

        guard let lastUpdated = store.object(forKey: type(of: self).updatedKey) as? Int,
                (now - lastUpdated < expirationDaysInSeconds
                || !isInternetReachable()) else {
            saveCurrentDate()
            return url(appendingTimestamp: now)
        }

        return url(appendingTimestamp: lastUpdated)
    }

    init(now: Int = Int(Date().timeIntervalSince1970),
         store: KeyValueDatabase = UserDefaults.standard,
         isInternetReachable: @escaping () -> Bool = ReachabilityUtils.isInternetReachable) {
        self.store = store
        self.now = now
        self.isInternetReachable = isInternetReachable
    }

    private func saveCurrentDate() {
        store.set(now, forKey: type(of: self).updatedKey)
    }

    private func url(appendingTimestamp appending: Int) -> String {
        guard let customURL = customAddress, !customURL.isEmpty else {
            let timestamp = String(appending)
            return "https://wordpress.com/calypso/reader-mobile.css?\(timestamp)"
        }

        let timestamp = String(appending)
        return "\(customURL)?\(timestamp)"
    }
}
