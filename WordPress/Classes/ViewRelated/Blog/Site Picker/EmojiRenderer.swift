import UIKit

/// Renders the specified emoji character into an image with the specified background color.
/// The image size and insets for the character can be overridden if necessary.
///
struct EmojiRenderer {
    let emoji: String
    let backgroundColor: UIColor
    let imageSize: CGSize
    let insetSize: CGFloat

    init(emoji: String, backgroundColor: UIColor, imageSize: CGSize = CGSize(width: 512.0, height: 512.0), insetSize: CGFloat = 16.0) {
        self.emoji = emoji
        self.backgroundColor = backgroundColor
        self.imageSize = imageSize
        self.insetSize = insetSize
    }

    func render() -> UIImage {
        let rect = CGRect(origin: .zero, size: imageSize)
        let insetRect = rect.insetBy(dx: insetSize, dy: insetSize)

        // The size passed in here doesn't matter, we just need the descriptor
        guard let font = UIFont.fontFittingText(emoji, in: insetRect.size, fontDescriptor: UIFont.systemFont(ofSize: 100).fontDescriptor) else {
            return UIImage()
        }

        let renderer = UIGraphicsImageRenderer(size: rect.size)
        let img = renderer.image { ctx in
            backgroundColor.setFill()
            ctx.fill(rect)

            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center

            let attrs: [NSAttributedString.Key: Any] = [.font: font, .paragraphStyle: paragraphStyle]
            emoji.draw(with: insetRect, options: .usesLineFragmentOrigin, attributes: attrs, context: nil)
        }

        return img
    }
}

private extension UIFont {
    /**
     Provides the largest font which fits the text in the given bounds.
     */
    static func fontFittingText(_ text: String, in bounds: CGSize, fontDescriptor: UIFontDescriptor) -> UIFont? {
        let properBounds = CGRect(origin: .zero, size: bounds)
        let largestFontSize = Int(bounds.height)
        let constrainingBounds = CGSize(width: properBounds.width, height: CGFloat.infinity)

        let bestFittingFontSize: Int? = (1...largestFontSize).reversed().first(where: { fontSize in
            let font = UIFont(descriptor: fontDescriptor, size: CGFloat(fontSize))
            let currentFrame = text.boundingRect(with: constrainingBounds, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: [.font: font], context: nil)

            if properBounds.contains(currentFrame) {
                return true
            }

            return false
        })

        guard let fontSize = bestFittingFontSize else { return nil }
        return UIFont(descriptor: fontDescriptor, size: CGFloat(fontSize))
    }
}
