import Foundation

@objc protocol WPRichTextMediaAttachment: NSObjectProtocol {
    var contentURL: URL? {get set}
    var linkURL: URL? {get set}
    var frame: CGRect {get set}
    func contentSize() -> CGSize
}
