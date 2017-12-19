import Foundation

open class WPRichTextImage: UIControl, WPRichTextMediaAttachment {

    // MARK: Properties

    var contentURL: URL?
    var linkURL: URL?
    @objc fileprivate(set) var imageView: UIImageView

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

    override init(frame: CGRect) {
        imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: frame.width, height: frame.height))
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        imageView.contentMode = .scaleAspectFit

        super.init(frame: frame)

        addSubview(imageView)
    }

    required public init?(coder aDecoder: NSCoder) {
        imageView = aDecoder.decodeObject(forKey: UIImage.classNameWithoutNamespaces()) as! UIImageView
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

    func contentSize() -> CGSize {
        if let size = imageView.image?.size {
            return size
        }
        return CGSize(width: 1.0, height: 1.0)
    }

    func contentRatio() -> CGFloat {
        if let size = imageView.image?.size {
            return size.width / size.height
        }
        return 0.0
    }

}
