import Foundation
import UIKit
import Aztec


final class CommentAttachmentRenderer {

    /// Comment Attachment Text
    ///
    let defaultText = NSLocalizedString("[COMMENT]", comment: "Comment Attachment Label")

    /// Text Color
    ///
    var textColor = UIColor.gray

    /// Text Font
    ///
    var textFont: UIFont


    /// Default Initializer
    ///
    init?(font: UIFont) {
        self.textFont = font
    }
}


// MARK: - TextViewCommentsDelegate Methods
//
extension CommentAttachmentRenderer: TextViewCommentsDelegate {

    func textView(_ textView: TextView, imageForComment attachment: CommentAttachment, with size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)

        let message = messageAttributedString()
        let targetRect = boundingRect(for: message, size: size)

        message.draw(in: targetRect)

        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return result
    }

    func textView(_ textView: TextView, boundsForComment attachment: CommentAttachment, with lineFragment: CGRect) -> CGRect {
        let message = messageAttributedString()

        let size = CGSize(width: lineFragment.size.width, height: lineFragment.size.height)
        var rect = boundingRect(for: message, size: size)
        rect.origin.y = textFont.descender

        return rect.integral
    }
}


// MARK: - Private Methods
//
private extension CommentAttachmentRenderer {

    func boundingRect(for message: NSAttributedString, size: CGSize) -> CGRect {
        let targetBounds = message.boundingRect(with: size, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
        let targetPosition = CGPoint(x: ((size.width - targetBounds.width) * 0.5), y: ((size.height - targetBounds.height) * 0.5))

        return CGRect(origin: targetPosition, size: targetBounds.size)
    }

    func messageAttributedString() -> NSAttributedString {
        let attributes: [String: Any] = [
            NSForegroundColorAttributeName: textColor,
            NSFontAttributeName: textFont
        ]

        return NSAttributedString(string: defaultText, attributes: attributes)
    }
}
