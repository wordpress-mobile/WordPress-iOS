import Foundation

@objc protocol WPRichTextMediaAttachment : NSObjectProtocol {
    var contentURL : NSURL? {get set}
    var linkURL : NSURL? {get set}
    var frame : CGRect {get set}
    func contentSize() -> CGSize
    func contentRatio() -> CGFloat
}