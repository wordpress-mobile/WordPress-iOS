import Foundation
import XCTest
@testable import WordPressKit

class SitePluginTests: XCTestCase {
    func testSitePluginCapabilitiesEquatableSucceeds() {
        let sitePluginCapabilitiesA = SitePluginCapabilities(modify: true, autoupdate: true)
        let sitePluginCapabilitiesB = SitePluginCapabilities(modify: true, autoupdate: true)

        XCTAssertEqual(sitePluginCapabilitiesA, sitePluginCapabilitiesB)
    }

    func testSitePluginCapabilitiesFails() {
        let sitePluginCapabilitiesA = SitePluginCapabilities(modify: true, autoupdate: true)
        let sitePluginCapabilitiesB = SitePluginCapabilities(modify: false, autoupdate: false)

        XCTAssertNotEqual(sitePluginCapabilitiesA, sitePluginCapabilitiesB)
    }
}
