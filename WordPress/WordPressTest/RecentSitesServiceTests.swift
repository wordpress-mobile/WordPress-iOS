import XCTest
import WordPress

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

    private func newService() -> RecentSitesService {
        return RecentSitesService(database: EphemeralKeyValueDatabase())
    }
}
