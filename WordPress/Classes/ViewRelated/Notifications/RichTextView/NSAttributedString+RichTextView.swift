import Foundation


extension NSAttributedString
{
    public func enumerateAttachments(block: (attachment: NSTextAttachment, range: NSRange) -> ()) {
        let range = NSMakeRange(0, length)
        
        enumerateAttribute(NSAttachmentAttributeName, inRange: range, options: .LongestEffectiveRangeNotRequired) {
            (value: AnyObject!, range: NSRange, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
            
            if let attachment = value as? NSTextAttachment {
                block(attachment: attachment, range: range)
            }
        }
    }
}
