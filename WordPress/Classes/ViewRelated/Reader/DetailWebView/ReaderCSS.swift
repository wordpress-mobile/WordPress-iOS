import Foundation

/// A struct that returns the Reader CSS URL
///
struct ReaderCSS {
    private let store: KeyValueDatabase

    private let now: Int = Int(Date().timeIntervalSince1970)

    private let twoDays: Int = 60 * 60 * 24 * 2

    /// Returns the Reader CSS appending a timestamp
    /// We force it to update every 2 days
    ///
    var address: String {
        guard let lastUpdated = store.object(forKey: "ReaderCSSLastUpdated") as? Int else {
            saveCurrentDate()
            return url(appendingTimestamp: now)
        }

        // If the last time we fetched the CSS was 2 days ago and the user is online, refresh it
        if now - lastUpdated >= twoDays && ReachabilityUtils.isInternetReachable() {
            saveCurrentDate()
            return url(appendingTimestamp: now)
        } else {
            return url(appendingTimestamp: lastUpdated)
        }
    }

    init(store: KeyValueDatabase = UserDefaults.standard) {
        self.store = store
    }

    private func saveCurrentDate() {
        store.set(now, forKey: "ReaderCSSLastUpdated")
    }

    private func url(appendingTimestamp appending: Int) -> String {
        let timestamp = String(appending)
        return "https://wordpress.com/calypso/reader-mobile.css?\(timestamp)"
    }
}
