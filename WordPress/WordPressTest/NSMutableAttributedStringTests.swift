import Foundation
import XCTest


open class NSMutableAttributedStringTests: XCTestCase {
    open func testApplyStylesToMatchesWithPattern() {
        // Assemble an Attributed string with bold markup markers
        let message = "This is a string that **contains bold substrings**"
        let regularStyle = [
            NSFontAttributeName: UIFont.systemFont(ofSize: 14),
            NSForegroundColorAttributeName: UIColor.gray
        ]

        let boldStyle = [
            NSFontAttributeName: UIFont.boldSystemFont(ofSize: 14),
            NSForegroundColorAttributeName: UIColor.black
        ]


        let attributedMessage = NSMutableAttributedString(string: message, attributes: regularStyle)
        let rawMessage = attributedMessage.string as NSString

        // Apply the Bold Style
        let boldPattern = "(\\*{1,2}).+?\\1"
        attributedMessage.applyStylesToMatchesWithPattern(boldPattern, styles: boldStyle)

        // Verify the regular style
        let regularExpectedRange = rawMessage.range(of: "This is a string that ")

        var regularEffectiveRange = NSMakeRange(0, rawMessage.length)
        let regularEffectiveStyle = attributedMessage.attributes(at: regularExpectedRange.location, effectiveRange: &regularEffectiveRange) as! [String : NSObject]

        XCTAssertEqual(regularEffectiveStyle, regularStyle, "Invalid Style Detected")
        XCTAssert(regularExpectedRange.location == regularEffectiveRange.location , "Invalid effective range")

        // Verify the bold style
        let boldExpectedRange = rawMessage.range(of: "**contains bold substrings**")

        var boldEffectiveRange = NSMakeRange(0, rawMessage.length)
        let boldEffectiveStyle = attributedMessage.attributes(at: boldExpectedRange.location, effectiveRange: &boldEffectiveRange) as! [String : NSObject]

        XCTAssertEqual(boldEffectiveStyle, boldStyle, "Invalid Style Detected")
        XCTAssert(boldExpectedRange.location == boldEffectiveRange.location , "Invalid effective range")
    }
}
