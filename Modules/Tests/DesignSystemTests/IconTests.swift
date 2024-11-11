import XCTest
import DesignSystem
import SwiftUI

final class IconTests: XCTestCase {

    // This test will fail if DesignSystem is built as a dynamic library. For some reason, Xcode can't locate
    // the library's resource bundle.
    //
    // DesignSystem will be built as a dynamic library if it's a dependency of a dynamic library, such as
    // the WordPressAuthenticator target.
    func testCanLoadAllIconsAsUIImage() throws {
        for icon in IconName.allCases {
            let _ = try XCTUnwrap(UIImage.DS.icon(named: icon))
        }
    }
}
