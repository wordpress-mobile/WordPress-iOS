import XCTest

@testable import WordPress

class ReaderCSSTests: XCTestCase {
    // MARK: - When online

    /// When requesting the CSS for the first time, use the current date in seconds
    ///
    func testOnlineFirstTime() {
        let now = Int(Date().timeIntervalSince1970)
        let database = EphemeralKeyValueDatabase()

        let readerCSS = ReaderCSS(now: now, store: database, isInternetReachable: { true })

        XCTAssertEqual(readerCSS.address, "https://wordpress.com/calypso/reader-mobile.css?\(now)")
    }

    /// When the CSS was requested at least 5 days ago, update the address
    ///
    func testOnlineExpired() {
        let now = Int(Date().timeIntervalSince1970)
        let fiveDaysAgo = now - 5 * 60 * 60 * 24
        let database = EphemeralKeyValueDatabase()
        database.set(fiveDaysAgo, forKey: ReaderCSS.updatedKey)

        let readerCSS = ReaderCSS(now: now, store: database, isInternetReachable: { true })

        XCTAssertEqual(readerCSS.address, "https://wordpress.com/calypso/reader-mobile.css?\(now)")
    }

    /// When the CSS was requested less than 5 days ago, use the time of when it was requested
    ///
    func testOnlineNotExpired() {
        let now = Int(Date().timeIntervalSince1970)
        let fourDaysAgo = now - 4 * 60 * 60 * 24
        let database = EphemeralKeyValueDatabase()
        database.set(fourDaysAgo, forKey: ReaderCSS.updatedKey)

        let readerCSS = ReaderCSS(now: now, store: database, isInternetReachable: { true })

        XCTAssertEqual(readerCSS.address, "https://wordpress.com/calypso/reader-mobile.css?\(fourDaysAgo)")
    }

    // MARK: - When offline

    /// When requesting the CSS for the first time, use the current date in seconds
    ///
    func testOfflineFirstTime() {
        let now = Int(Date().timeIntervalSince1970)
        let database = EphemeralKeyValueDatabase()

        let readerCSS = ReaderCSS(now: now, store: database, isInternetReachable: { false })

        XCTAssertEqual(readerCSS.address, "https://wordpress.com/calypso/reader-mobile.css?\(now)")
    }

    /// When the CSS was requested at least 5 days ago but device isssss offline, keep the address
    ///
    func testOfflineExpired() {
        let now = Int(Date().timeIntervalSince1970)
        let fiveDaysAgo = now - 5 * 60 * 60 * 24
        let database = EphemeralKeyValueDatabase()
        database.set(fiveDaysAgo, forKey: ReaderCSS.updatedKey)

        let readerCSS = ReaderCSS(now: now, store: database, isInternetReachable: { false })

        XCTAssertEqual(readerCSS.address, "https://wordpress.com/calypso/reader-mobile.css?\(fiveDaysAgo)")
    }

    /// When the CSS was requested less than 5 days ago and we're offline, keep the old timestamp
    ///
    func testOfflineNotExpired() {
        let now = Int(Date().timeIntervalSince1970)
        let fourDaysAgo = now - 4 * 60 * 60 * 24
        let database = EphemeralKeyValueDatabase()
        database.set(fourDaysAgo, forKey: ReaderCSS.updatedKey)

        let readerCSS = ReaderCSS(now: now, store: database, isInternetReachable: { false })

        XCTAssertEqual(readerCSS.address, "https://wordpress.com/calypso/reader-mobile.css?\(fourDaysAgo)")
    }
}
