import Foundation
import UIKit

extension NSAttributedString {
    @objc public func enumerateAttachments(_ block: @escaping (_ attachment: NSTextAttachment, _ range: NSRange) -> ()) {
        let range = NSMakeRange(0, length)

        enumerateAttribute(.attachment, in: range, options: .longestEffectiveRangeNotRequired) {
            (value: Any?, range: NSRange, stop: UnsafeMutablePointer<ObjCBool>) -> Void in

            if let attachment = value as? NSTextAttachment {
                block(attachment, range)
            }
        }
    }
}
