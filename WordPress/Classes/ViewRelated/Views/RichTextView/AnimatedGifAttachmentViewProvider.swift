import UIKit
import Gifu

/**
 * This adds custom view rendering for animated Gif images in a UITextView
 * This can be used by using: `NSTextAttachment.registerViewProviderClass`
 *
 */
class AnimatedGifAttachmentViewProvider: NSTextAttachmentViewProvider {
    deinit {
        guard let animatedImageView = view as? GIFImageView else {
            return
        }
        animatedImageView.reset()
    }

    override init(textAttachment: NSTextAttachment, parentView: UIView?, textLayoutManager: NSTextLayoutManager?, location: NSTextLocation) {
        super.init(textAttachment: textAttachment, parentView: parentView, textLayoutManager: textLayoutManager, location: location)
        guard let contents = textAttachment.contents else {
            return
        }

        let imageView = GIFImageView(frame: parentView?.bounds ?? .zero)
        imageView.animate(withGIFData: contents)

        view = imageView
    }

    override func loadView() {
        super.loadView()
    }
}
