import Foundation

open class WPRichTextImage: UIControl, WPRichTextMediaAttachment {

    // MARK: Properties

    var contentURL: URL?
    var linkURL: URL?

    @objc fileprivate(set) var imageView: CachedAnimatedImageView

    fileprivate lazy var imageLoader: ImageLoader = {
        let imageLoader = ImageLoader(imageView: imageView, gifStrategy: .smallGIFs)
        imageLoader.photonQuality = Constants.readerPhotonQuality
        return imageLoader
    }()

    override open var frame: CGRect {
        didSet {
            // If Voice Over is enabled, the OS will query for the accessibilityPath
            // to know what region of the screen to highlight. If the path is nil
            // the OS should fall back to computing based on the frame but this
            // may be bugged. Setting the accessibilityPath avoids a crash.
            accessibilityPath = UIBezierPath(rect: frame)
        }
    }


    // MARK: Lifecycle

    deinit {
        imageView.clean()
    }

    override init(frame: CGRect) {
        imageView = CachedAnimatedImageView(frame: CGRect(x: 0, y: 0, width: frame.width, height: frame.height))
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        imageView.contentMode = .scaleAspectFit
        imageView.isAccessibilityElement = true

        super.init(frame: frame)

        addSubview(imageView)
    }

    required public init?(coder aDecoder: NSCoder) {
        imageView = aDecoder.decodeObject(forKey: UIImage.classNameWithoutNamespaces()) as! CachedAnimatedImageView
        contentURL = aDecoder.decodeObject(forKey: "contentURL") as! URL?
        linkURL = aDecoder.decodeObject(forKey: "linkURL") as! URL?

        super.init(coder: aDecoder)
    }

    override open func encode(with aCoder: NSCoder) {
        aCoder.encode(imageView, forKey: UIImage.classNameWithoutNamespaces())

        if let url = contentURL {
            aCoder.encode(url, forKey: "contentURL")
        }

        if let url = linkURL {
            aCoder.encode(url, forKey: "linkURL")
        }

        super.encode(with: aCoder)
    }


    // MARK: Public Methods

    /// Load an image with the already-set contentURL property. Supports animated images (gifs) as well.
    ///
    /// - Parameters:
    ///   - contentInformation: The corresponding ImageSourceInformation for the contentURL
    ///   - preferedSize: The prefered size of the image to load.
    ///   - indexPath: The IndexPath where this view is located — returned as a param in success and error blocks.
    ///   - onSuccess: A closure to be called if the image was loaded successfully.
    ///   - onError: A closure to be called if there was an error loading the image.
    func loadImage(from contentInformation: ImageSourceInformation,
                   preferedSize size: CGSize = .zero,
                   indexPath: IndexPath,
                   onSuccess: ((IndexPath) -> Void)?,
                   onError: ((IndexPath, Error?) -> Void)?) {
        guard let contentURL = self.contentURL else {
            onError?(indexPath, nil)
            return
        }

        let successHandler: (() -> Void)? = {
            onSuccess?(indexPath)
        }

        let errorHandler: ((Error?) -> Void)? = { error in
            onError?(indexPath, error)
        }

        imageLoader.loadImage(with: contentURL, from: contentInformation, preferredSize: size, placeholder: nil, success: successHandler, error: errorHandler)
    }

    func contentSize() -> CGSize {
        let size = imageView.intrinsicContentSize
        guard size.height > 0, size.width > 0 else {
            return CGSize(width: 1.0, height: 1.0)
        }
        return imageView.intrinsicContentSize
    }

    func clean() {
        imageView.clean()
        imageView.prepForReuse()
    }
}

private extension WPRichTextImage {
    enum Constants {
        static let readerPhotonQuality: UInt = 65
    }
}
