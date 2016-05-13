import Foundation
import XCTest
@testable import WordPress

class WPComReferrerUtilTests: XCTestCase {

    func testAddUtmSourceToURLPath() {
        let utmSource = "utm_source=https://wordpress.com"

        // Test a regular path
        var path = "/url/path"
        var newPath = WPComReferrerUtil.addUtmSourceToURLPath(path)
        var match = "\(path)?\(utmSource)"
        XCTAssert(newPath == match, "The utm_source was not added correctly")

        // Test an existing query
        path = "/url/path?existing=param"
        newPath = WPComReferrerUtil.addUtmSourceToURLPath(path)
        match = "\(path)&\(utmSource)"
        XCTAssert(newPath == match, "The utm_source was not added correctly")

        // Test an existing utm_source
        path = "/url/path?existing=param&utm_source=foo"
        newPath = WPComReferrerUtil.addUtmSourceToURLPath(path)
        XCTAssert(newPath == path, "A string with an existing utm source should not be changed.")
    }

}
