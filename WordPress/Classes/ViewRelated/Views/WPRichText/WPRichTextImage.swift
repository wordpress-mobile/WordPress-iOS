import UIKit
import WordPressMedia
import Gifu

class WPRichTextImage: UIControl, WPRichTextMediaAttachment {

    // MARK: Properties

    var contentURL: URL?
    var linkURL: URL?

    @objc fileprivate(set) var imageView: AsyncImageView

    override var frame: CGRect {
        didSet {
            // If Voice Over is enabled, the OS will query for the accessibilityPath
            // to know what region of the screen to highlight. If the path is nil
            // the OS should fall back to computing based on the frame but this
            // may be bugged. Setting the accessibilityPath avoids a crash.
            accessibilityPath = UIBezierPath(rect: frame)
        }
    }

    // MARK: Lifecycle

    override init(frame: CGRect) {
        imageView = AsyncImageView(frame: CGRect(x: 0, y: 0, width: frame.width, height: frame.height))
        imageView.configuration.passTouchesToSuperview = true
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        imageView.contentMode = .scaleAspectFit
        imageView.isAccessibilityElement = true

        super.init(frame: frame)

        addSubview(imageView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Public Methods

    /// Load an image with the already-set contentURL property. Supports animated images (gifs) as well.
    ///
    /// - Parameters:
    ///   - host: The host for the media.
    ///   - preferedSize: The prefered size of the image to load.
    ///   - onSuccess: A closure to be called if the image was loaded successfully.
    ///   - onError: A closure to be called if there was an error loading the image.
    func loadImage(from host: MediaHost,
                   preferedSize size: CGSize = .zero,
                   onSuccess: (() -> Void)?,
                   onError: ((Error?) -> Void)?) {
        guard let contentURL = self.contentURL else {
            onError?(nil)
            return
        }

        imageView.setImage(with: ImageRequest(url: contentURL, host: host)) { result in
            switch result {
            case .success: onSuccess?()
            case .failure(let error): onError?(error)
            }
        }
    }

    func contentSize() -> CGSize {
        guard let size = imageView.image?.size, size.height > 0, size.width > 0 else {
            return CGSize(width: 44.0, height: 44.0)
        }
        return size
    }

    func clean() {
        imageView.prepareForReuse()
    }
}
