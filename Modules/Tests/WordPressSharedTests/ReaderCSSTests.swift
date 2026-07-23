import Foundation
import Testing

@testable import WordPressShared

struct ReaderCSSTests {
    // MARK: - When online

    /// When requesting the CSS for the first time, use the current date in seconds
    ///
    @Test func testOnlineFirstTime() {
        let now = Int(Date().timeIntervalSince1970)
        let database = EphemeralKeyValueDatabase()

        let readerCSS = ReaderCSS(now: now, store: database, isInternetReachable: { true })

        #expect(readerCSS.address == "https://wordpress.com/calypso/reader-mobile.css?\(now)")
    }

    /// When the CSS was requested at least 5 days ago, update the address
    ///
    @Test func testOnlineExpired() {
        let now = Int(Date().timeIntervalSince1970)
        let fiveDaysAgo = now - 5 * 60 * 60 * 24
        let database = EphemeralKeyValueDatabase()
        database.set(fiveDaysAgo, forKey: ReaderCSS.updatedKey)

        let readerCSS = ReaderCSS(now: now, store: database, isInternetReachable: { true })

        #expect(readerCSS.address == "https://wordpress.com/calypso/reader-mobile.css?\(now)")
    }

    /// When the CSS was requested less than 5 days ago, use the time of when it was requested
    ///
    @Test func testOnlineNotExpired() {
        let now = Int(Date().timeIntervalSince1970)
        let fourDaysAgo = now - 4 * 60 * 60 * 24
        let database = EphemeralKeyValueDatabase()
        database.set(fourDaysAgo, forKey: ReaderCSS.updatedKey)

        let readerCSS = ReaderCSS(now: now, store: database, isInternetReachable: { true })

        #expect(readerCSS.address == "https://wordpress.com/calypso/reader-mobile.css?\(fourDaysAgo)")
    }

    // MARK: - When offline

    /// When requesting the CSS for the first time, use the current date in seconds
    ///
    @Test func testOfflineFirstTime() {
        let now = Int(Date().timeIntervalSince1970)
        let database = EphemeralKeyValueDatabase()

        let readerCSS = ReaderCSS(now: now, store: database, isInternetReachable: { false })

        #expect(readerCSS.address == "https://wordpress.com/calypso/reader-mobile.css?\(now)")
    }

    /// When the CSS was requested at least 5 days ago but device isssss offline, keep the address
    ///
    @Test func testOfflineExpired() {
        let now = Int(Date().timeIntervalSince1970)
        let fiveDaysAgo = now - 5 * 60 * 60 * 24
        let database = EphemeralKeyValueDatabase()
        database.set(fiveDaysAgo, forKey: ReaderCSS.updatedKey)

        let readerCSS = ReaderCSS(now: now, store: database, isInternetReachable: { false })

        #expect(readerCSS.address == "https://wordpress.com/calypso/reader-mobile.css?\(fiveDaysAgo)")
    }

    /// When the CSS was requested less than 5 days ago and we're offline, keep the old timestamp
    ///
    @Test func testOfflineNotExpired() {
        let now = Int(Date().timeIntervalSince1970)
        let fourDaysAgo = now - 4 * 60 * 60 * 24
        let database = EphemeralKeyValueDatabase()
        database.set(fourDaysAgo, forKey: ReaderCSS.updatedKey)

        let readerCSS = ReaderCSS(now: now, store: database, isInternetReachable: { false })

        #expect(readerCSS.address == "https://wordpress.com/calypso/reader-mobile.css?\(fourDaysAgo)")
    }
}
