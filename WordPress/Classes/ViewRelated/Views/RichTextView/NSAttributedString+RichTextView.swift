import Foundation
import UIKit


// NOTE:
// This is not cool. The reason why we need this constant, is because DTCoreText overrides NSAttachmentAttributeName.
// Even using Swift's namespaces ("UIKit.NSAttachmentAttributeName") doesn't return the right value.
// Please, nuke DTCoreText, and remove this constant.
//
public let UIKitAttachmentAttributeName = "NSAttachment"

extension NSAttributedString {
    public func enumerateAttachments(_ block: @escaping (_ attachment: NSTextAttachment, _ range: NSRange) -> ()) {
        let range = NSMakeRange(0, length)

        enumerateAttribute(UIKitAttachmentAttributeName, in: range, options: .longestEffectiveRangeNotRequired) {
            (value: Any?, range: NSRange, stop: UnsafeMutablePointer<ObjCBool>) -> Void in

            if let attachment = value as? NSTextAttachment {
                block(attachment, range)
            }
        }
    }
}
