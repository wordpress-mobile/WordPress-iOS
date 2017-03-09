import XCTest
import WordPress

class RecentSitesServiceTests: XCTestCase {
    func testEmptyByDefault() {
        let service = newService()
        XCTAssertEqual(service.recentSites.count, 0)
    }

    func testRecentSitesLimited() {
        let service = newService()
        service.touch(site: 123)
        service.touch(site: 234)
        service.touch(site: 345)
        service.touch(site: 456)
        XCTAssertEqual(service.recentSites, [456, 345, 234])
    }

    func testDoesNotDuplicate() {
        let service = newService()
        service.touch(site: 123)
        service.touch(site: 234)
        service.touch(site: 123)
        XCTAssertEqual(service.recentSites, [123, 234])
    }

    private func newService() -> RecentSitesService {
        return RecentSitesService(database: EphemeralKeyValueDatabase())
    }
}
