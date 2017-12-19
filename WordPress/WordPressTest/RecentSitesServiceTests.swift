import XCTest
@testable import WordPress

class RecentSitesServiceTests: XCTestCase {
    func testEmptyByDefault() {
        let service = newService()
        XCTAssertEqual(service.recentSites.count, 0)
    }

    func testRecentSitesLimited() {
        let service = newService()
        service.touch(site: "site1")
        service.touch(site: "site2")
        service.touch(site: "site3")
        service.touch(site: "site4")
        XCTAssertEqual(service.recentSites, ["site4", "site3", "site2"])
    }

    func testDoesNotDuplicate() {
        let service = newService()
        service.touch(site: "site1")
        service.touch(site: "site2")
        service.touch(site: "site1")
        XCTAssertEqual(service.recentSites, ["site1", "site2"])
    }

    func testMigratesLastBlogUsed() {
        let database = EphemeralKeyValueDatabase()
        database.set("site1", forKey: "LastUsedBlogURLDefaultsKey")
        let service = RecentSitesService(database: database)
        XCTAssertEqual(service.recentSites, ["site1"])
    }

    private func newService() -> RecentSitesService {
        return RecentSitesService(database: EphemeralKeyValueDatabase())
    }

    func testTouchSiteSendsNotification() {
        expectation(forNotification: NSNotification.Name.WPRecentSitesChanged, object: nil, handler: nil)
        let service = newService()
        service.touch(site: "site1")
        waitForExpectations(timeout: 0.01, handler: nil)
    }
}
