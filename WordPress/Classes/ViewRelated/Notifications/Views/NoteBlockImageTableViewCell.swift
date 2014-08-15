import Foundation


@objc public class NoteBlockImageTableViewCell : NoteBlockTableViewCell
{
    // MARK: IBOutlets
    @IBOutlet weak var blockImageView:  UIImageView!
    
    // MARK: Private
    private struct Animation {
        static let duration:            NSTimeInterval  = 0.5
        static let delay:               NSTimeInterval  = 0.2
        static let damping:             CGFloat         = 0.7
        static let velocity:            CGFloat         = 0.5
        static let scaleInitial:        CGFloat         = 0.0
        static let scaleFinal:          CGFloat         = 1.0
        
        static var transformInitial: CGAffineTransform {
            return CGAffineTransformMakeScale(scaleInitial, scaleInitial)
        }
        
        static var transformFinal: CGAffineTransform {
            return CGAffineTransformMakeScale(scaleFinal, scaleFinal)
        }
    }
    
    public var imageURL: NSURL? {
        didSet {
            self.reloadImage()
        }
    }
    
    public override func awakeFromNib() {
        assert(self.blockImageView)
        selectionStyle  = .None
        backgroundColor = Notification.Colors.blockBackground
    }
    
    private func reloadImage() {
        if let url = imageURL {
            downloadImage(url)
        } else {
            blockImageView.image = nil
        }
    }
    
    private func downloadImage(url: NSURL) {
        blockImageView.setImageWithURLRequest(
            NSURLRequest(URL: url),
            placeholderImage: nil,
            success: {
            // TODO: Uncomment when the compiler is fixed
            //                [unowned self]
                (request: NSURLRequest!, response: NSHTTPURLResponse!, image: UIImage!) -> Void in
                if image {
                    self.animateImage(image)
                }
            },
            failure: nil)
    }
    
    private func animateImage(image: UIImage) {
        blockImageView.image        = image
        blockImageView.hidden       = false
        blockImageView.transform    = Animation.transformInitial
        
        var animations = {
            () -> Void in
            self.blockImageView.transform = Animation.transformFinal
        }
        
        UIView.animateWithDuration(Animation.duration,
            delay:                  Animation.delay,
            usingSpringWithDamping: Animation.damping,
            initialSpringVelocity:  Animation.velocity,
            options:                nil,
            animations:             animations,
            completion:             nil
        )
    }
}
