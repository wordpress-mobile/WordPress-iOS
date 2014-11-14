import Foundation
import UIKit


// NOTE: 
// This is not cool. The reason why we need this constant, is because DTCoreText overrides NSAttachmentAttributeName.
// Even using Swift's namespaces ("UIKit.NSAttachmentAttributeName") doesn't return the right value.
// Please, nuke DTCoreText, and remove this constant.
//
public let UIKitAttachmentAttributeName = "NSAttachment"

extension NSAttributedString
{
    public func enumerateAttachments(block: (attachment: NSTextAttachment, range: NSRange) -> ()) {
        let range = NSMakeRange(0, length)

        enumerateAttribute(UIKitAttachmentAttributeName, inRange: range, options: .LongestEffectiveRangeNotRequired) {
            (value: AnyObject!, range: NSRange, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
            
            if let attachment = value as? NSTextAttachment {
                block(attachment: attachment, range: range)
            }
        }
    }
}
