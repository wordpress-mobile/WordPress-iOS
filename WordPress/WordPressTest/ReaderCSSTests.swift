import XCTest

@testable import WordPress

class ReaderCSSTests: XCTestCase {
    // MARK: - When online

    func testOnlineFirstTime() {
        let now = Int(Date().timeIntervalSince1970)
        let database = EphemeralKeyValueDatabase()

        let readerCSS = ReaderCSS(now: now, store: database, isInternetReachable: { true })

        XCTAssertEqual(readerCSS.address, "https://wordpress.com/calypso/reader-mobile.css?\(now)")
    }

    func testOnlineExpired() {
        let now = Int(Date().timeIntervalSince1970)
        let fiveDaysAgo = now - 5 * 60 * 60 * 24
        let database = EphemeralKeyValueDatabase()
        database.set(fiveDaysAgo, forKey: ReaderCSS.updatedKey)

        let readerCSS = ReaderCSS(now: now, store: database, isInternetReachable: { true })

        XCTAssertEqual(readerCSS.address, "https://wordpress.com/calypso/reader-mobile.css?\(now)")
    }

    func testOnlineNotExpired() {
        let now = Int(Date().timeIntervalSince1970)
        let fourDaysAgo = now - 4 * 60 * 60 * 24
        let database = EphemeralKeyValueDatabase()
        database.set(fourDaysAgo, forKey: ReaderCSS.updatedKey)

        let readerCSS = ReaderCSS(now: now, store: database, isInternetReachable: { true })

        XCTAssertEqual(readerCSS.address, "https://wordpress.com/calypso/reader-mobile.css?\(fourDaysAgo)")
    }

    // MARK: - When offline

    func testOfflineFirstTime() {
        let now = Int(Date().timeIntervalSince1970)
        let database = EphemeralKeyValueDatabase()

        let readerCSS = ReaderCSS(now: now, store: database, isInternetReachable: { false })

        XCTAssertEqual(readerCSS.address, "https://wordpress.com/calypso/reader-mobile.css?\(now)")
    }

    func testOfflineExpired() {
        let now = Int(Date().timeIntervalSince1970)
        let fiveDaysAgo = now - 5 * 60 * 60 * 24
        let database = EphemeralKeyValueDatabase()
        database.set(fiveDaysAgo, forKey: ReaderCSS.updatedKey)

        let readerCSS = ReaderCSS(now: now, store: database, isInternetReachable: { false })

        XCTAssertEqual(readerCSS.address, "https://wordpress.com/calypso/reader-mobile.css?\(fiveDaysAgo)")
    }

    func testOfflineNotExpired() {
        let now = Int(Date().timeIntervalSince1970)
        let fourDaysAgo = now - 4 * 60 * 60 * 24
        let database = EphemeralKeyValueDatabase()
        database.set(fourDaysAgo, forKey: ReaderCSS.updatedKey)

        let readerCSS = ReaderCSS(now: now, store: database, isInternetReachable: { false })

        XCTAssertEqual(readerCSS.address, "https://wordpress.com/calypso/reader-mobile.css?\(fourDaysAgo)")
    }
}
