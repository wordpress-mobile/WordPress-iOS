import XCTest
import DesignSystem
import SwiftUI

final class IconTests: XCTestCase {

    func testCanLoadAllIconsAsUIImage() throws {
        for icon in IconName.allCases {
            let _ = try XCTUnwrap(UIImage.DS.icon(named: icon))
        }
    }
}
