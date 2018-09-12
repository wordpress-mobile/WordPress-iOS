import Foundation
import XCTest

class NSMutableAttributedStringTests: XCTestCase {
    func testApplyStylesToMatchesWithPattern() {
        // Assemble an Attributed string with bold markup markers
        let message = "This is a string that **contains bold substrings**"
        let regularStyle: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor.gray
        ]

        let boldStyle: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 14),
            .foregroundColor: UIColor.black
        ]


        let attributedMessage = NSMutableAttributedString(string: message, attributes: regularStyle)
        let rawMessage = attributedMessage.string as NSString

        // Apply the Bold Style
        let boldPattern = "(\\*{1,2}).+?\\1"
        attributedMessage.applyStylesToMatchesWithPattern(boldPattern, styles: boldStyle)

        // Verify the regular style
        let regularExpectedRange = rawMessage.range(of: "This is a string that ")

        var regularEffectiveRange = NSMakeRange(0, rawMessage.length)
        let regularEffectiveStyle = attributedMessage.attributes(at: regularExpectedRange.location, effectiveRange: &regularEffectiveRange)

        XCTAssert(isEqual(regularEffectiveStyle, regularStyle), "Invalid Style Detected")
        XCTAssert(regularExpectedRange.location == regularEffectiveRange.location, "Invalid effective range")

        // Verify the bold style
        let boldExpectedRange = rawMessage.range(of: "**contains bold substrings**")

        var boldEffectiveRange = NSMakeRange(0, rawMessage.length)
        let boldEffectiveStyle = attributedMessage.attributes(at: boldExpectedRange.location, effectiveRange: &boldEffectiveRange)

        XCTAssert(isEqual(boldEffectiveStyle, boldStyle), "Invalid Style Detected")
        XCTAssert(boldExpectedRange.location == boldEffectiveRange.location, "Invalid effective range")
    }


    ///
    ///
    private func isEqual(_ lhs: [NSAttributedString.Key: Any], _ rhs: [NSAttributedString.Key: Any]) -> Bool {
        guard lhs.count == rhs.count else {
            return false
        }

        for (key, value) in lhs {
            let left = rhs[key] as AnyObject
            let right = value as AnyObject

            if !left.isEqual(right) {
                return false
            }
        }

        return true
    }
}
