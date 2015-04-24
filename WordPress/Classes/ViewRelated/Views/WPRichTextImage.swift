import Foundation

class WPRichTextImage : UIControl, WPRichTextMediaAttachment {

    // MARK: Properties

    var contentURL : NSURL?
    var linkURL : NSURL?
    private(set) var imageView : UIImageView

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
        imageView = UIImageView(frame: CGRectMake(0, 0, frame.width, frame.height));
        imageView.autoresizingMask = .FlexibleWidth | .FlexibleHeight
        imageView.contentMode = .ScaleAspectFit

        super.init(frame: frame)

        addSubview(imageView)
    }

    required init(coder aDecoder: NSCoder) {
        imageView = aDecoder.decodeObjectForKey(UIImage.classNameWithoutNamespaces()) as! UIImageView
        contentURL = aDecoder.decodeObjectForKey("contentURL") as! NSURL?
        linkURL = aDecoder.decodeObjectForKey("linkURL") as! NSURL?

        super.init(coder: aDecoder)
    }

    override func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(imageView, forKey: UIImage.classNameWithoutNamespaces());

        if let url = contentURL {
            aCoder.encodeObject(url, forKey: "contentURL")
        }

        if let url = linkURL {
            aCoder.encodeObject(url, forKey: "linkURL")
        }

        super.encodeWithCoder(aCoder)
    }


    // MARK: Public Methods

    func contentSize() -> CGSize {
        if let size = imageView.image?.size {
            return size
        }
        return CGSizeMake(1.0, 1.0)
    }

    func contentRatio() -> CGFloat {
        if let size = imageView.image?.size {
            return size.width / size.height
        }
        return 0.0
    }

}
