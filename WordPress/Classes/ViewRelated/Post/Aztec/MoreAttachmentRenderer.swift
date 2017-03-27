import Foundation
import UIKit
import Aztec


// MARK: - MoreAttachmentRenderer: Renders More Comments!
//
final class MoreAttachmentRenderer {

    /// Attachment to be rendered
    ///
    let attachment: CommentAttachment

    /// Text Color
    ///
    var textColor = UIColor.gray


    /// Default Initializer: Returns *nil* whenever the Attachment's text is not *more*.
    /// This render is expected to only work with `<!--more-->` comments!
    ///
    init?(attachment: CommentAttachment) {
        self.attachment = attachment

        guard attachment.text == Constants.defaultCommentText else {
            return nil
        }
    }
}


// MARK: - TextViewCommentsDelegate Methods
//
extension MoreAttachmentRenderer: TextViewCommentsDelegate {

    func textView(_ textView: TextView, imageForComment attachment: CommentAttachment, with size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)

        let label = attachment.text.uppercased()
        let attributes = [NSForegroundColorAttributeName: textColor]
        let colorMessage = NSAttributedString(string: label, attributes: attributes)

        let textRect = colorMessage.boundingRect(with: size, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
        let textPosition = CGPoint(x: ((size.width - textRect.width) * 0.5), y: ((size.height - textRect.height) * 0.5))
        colorMessage.draw(in: CGRect(origin: textPosition , size: CGSize(width: size.width, height: textRect.size.height)))

        let path = UIBezierPath()

        let dashes = [ Constants.defaultDashCount, Constants.defaultDashCount ]
        path.setLineDash(dashes, count: dashes.count, phase: 0.0)
        path.lineWidth = Constants.defaultDashWidth

        let centerY = round(size.height * 0.5)
        path.move(to: CGPoint(x: 0, y: centerY))
        path.addLine(to: CGPoint(x: ((size.width - textRect.width) * 0.5) - Constants.defaultDashWidth, y: centerY))

        path.move(to: CGPoint(x:((size.width + textRect.width) * 0.5) + Constants.defaultDashWidth, y: centerY))
        path.addLine(to: CGPoint(x: size.width, y: centerY))

        textColor.setStroke()
        path.stroke()

        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return result
    }

    func textView(_ textView: TextView, boundsForComment attachment: CommentAttachment, with lineFragment: CGRect) -> CGRect {
        let padding = textView.textContainer.lineFragmentPadding
        let width = lineFragment.width - padding * 2

        return CGRect(origin: .zero, size: CGSize(width: width, height: Constants.defaultHeight))
    }
}


// MARK: - Constants
//
extension MoreAttachmentRenderer {

    struct Constants {
        static let defaultDashCount = CGFloat(8.0)
        static let defaultDashWidth = CGFloat(2.0)
        static let defaultHeight = CGFloat(44.0)
        static let defaultCommentText = "more"
    }
}
