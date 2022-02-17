import UIKit

/**
 * This adds custom view rendering for animated Gif images in a UITextView
 * This can be used by using: `NSTextAttachment.registerViewProviderClass`
 *
 */
@available(iOS 15.0, *)
class AnimatedGifAttachmentViewProvider: NSTextAttachmentViewProvider {
    deinit {
        guard let animatedImageView = view as? CachedAnimatedImageView else {
            return
        }

        animatedImageView.stopAnimating()
    }

    override init(textAttachment: NSTextAttachment, parentView: UIView?, textLayoutManager: NSTextLayoutManager?, location: NSTextLocation) {
        super.init(textAttachment: textAttachment, parentView: parentView, textLayoutManager: textLayoutManager, location: location)
        guard let contents = textAttachment.contents else {
            return
        }

        let imageView = CachedAnimatedImageView(frame: parentView?.bounds ?? .zero)
        imageView.setAnimatedImage(contents)

        view = imageView
    }

    override func loadView() {
        super.loadView()
    }
}
