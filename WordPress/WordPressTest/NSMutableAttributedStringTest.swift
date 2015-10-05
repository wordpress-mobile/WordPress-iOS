import Foundation
import XCTest


public class NSMutableAttributedStringTests : XCTestCase
{
    public func testApplyStylesToMatchesWithPattern() {
        // Assemble an Attributed string with bold markup markers
        let message = "This is a string that **contains bold substrings**"
        let regularStyle = [
            NSFontAttributeName             : UIFont.systemFontOfSize(14),
            NSForegroundColorAttributeName  : UIColor.grayColor()
        ]
        
        let boldStyle = [
            NSFontAttributeName             : UIFont.boldSystemFontOfSize(14),
            NSForegroundColorAttributeName  : UIColor.blackColor()
        ]
        
        
        let attributedMessage = NSMutableAttributedString(string: message, attributes: regularStyle)
        let rawMessage = attributedMessage.string as NSString
        
        // Apply the Bold Style
        let boldPattern = "(\\*{1,2}).+?\\1"
        attributedMessage.applyStylesToMatchesWithPattern(boldPattern, styles: boldStyle)
        
        // Verify the regular style
        let regularExpectedRange = rawMessage.rangeOfString("This is a string that ")
        
        var regularEffectiveRange = NSMakeRange(0, rawMessage.length)
        let regularEffectiveStyle = attributedMessage.attributesAtIndex(regularExpectedRange.location, effectiveRange: &regularEffectiveRange) as! [String : NSObject]
        
        XCTAssertEqual(regularEffectiveStyle, regularStyle, "Invalid Style Detected")
        XCTAssert(regularExpectedRange.location == regularEffectiveRange.location , "Invalid effective range")
        
        // Verify the bold style
        let boldExpectedRange = rawMessage.rangeOfString("**contains bold substrings**")
        
        var boldEffectiveRange = NSMakeRange(0, rawMessage.length)
        let boldEffectiveStyle = attributedMessage.attributesAtIndex(boldExpectedRange.location, effectiveRange: &boldEffectiveRange) as! [String : NSObject]
        
        XCTAssertEqual(boldEffectiveStyle, boldStyle, "Invalid Style Detected")
        XCTAssert(boldExpectedRange.location == boldEffectiveRange.location , "Invalid effective range")
    }
}
