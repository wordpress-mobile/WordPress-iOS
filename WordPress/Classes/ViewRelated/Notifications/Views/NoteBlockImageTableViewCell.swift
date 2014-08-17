import Foundation


@objc public class NoteBlockImageTableViewCell : NoteBlockTableViewCell
{
    // Mark - Public Methods
    public func downloadImageWithURL(url: NSURL?) {
        if url == imageURL {
            return
        }

        if let unwrappedURL = url {
            blockImageView.downloadImage(unwrappedURL,
                placeholderImage: nil,
                success: displayImageWithAnimation,
                failure: nil
            )
        } else {
            blockImageView.image = nil
        }
        
        imageURL = url
    }
    
    // MARK - View Methods
    public override func awakeFromNib() {
        assert(blockImageView)
        selectionStyle  = .None
        backgroundColor = Notification.Colors.blockBackground
    }
    
    // MARK - Private Methods
    private func displayImageWithAnimation(image: UIImage) {
        blockImageView.image        = image
        blockImageView.hidden       = false
        blockImageView.transform    = Animation.transformInitial
        
        var animations = {
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
    
    // MARK - Private
    private struct Animation {
        static let duration     = 0.5
        static let delay        = 0.2
        static let damping      = CGFloat(0.7)
        static let velocity     = CGFloat(0.5)
        static let scaleInitial = CGFloat(0.0)
        static let scaleFinal   = CGFloat(1.0)
        
        static var transformInitial: CGAffineTransform {
        return CGAffineTransformMakeScale(scaleInitial, scaleInitial)
        }
        
        static var transformFinal: CGAffineTransform {
        return CGAffineTransformMakeScale(scaleFinal, scaleFinal)
        }
    }
    private var imageURL:               NSURL?
    
    // MARK: - IBOutlets
    @IBOutlet weak var blockImageView:  UIImageView!
}
