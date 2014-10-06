import Foundation

class WPRichTextImage : UIControl, WPRichTextMediaAttachment {

    // MARK: Properties

    var contentURL : NSURL?
    var linkURL : NSURL?
    private(set) var imageView : UIImageView


    // MARK: Lifecycle

    override init(frame: CGRect) {
        imageView = UIImageView(frame: CGRectMake(0, 0, CGRectGetWidth(frame), CGRectGetHeight(frame)));
        imageView.autoresizingMask = UIViewAutoresizing.FlexibleWidth | UIViewAutoresizing.FlexibleHeight
        imageView.contentMode = UIViewContentMode.ScaleAspectFit

        super.init(frame: frame);

        addSubview(imageView)
    }

    required init(coder aDecoder: NSCoder) {
        imageView = aDecoder.decodeObjectForKey(UIImage.classNameWithoutNamespaces()) as UIImageView
        contentURL = aDecoder.decodeObjectForKey("contentURL") as NSURL?
        linkURL = aDecoder.decodeObjectForKey("linkURL") as NSURL?

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


    // TODO: Public Methods

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
