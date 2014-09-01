import Foundation


@objc public class NoteBlockImageTableViewCell : NoteBlockTableViewCell
{
    // MARK: - Public Properties
    public var isBadge: Bool = false {
        didSet {
            if isBadge {
                backgroundColor = WPStyleGuide.Notifications.badgeBackgroundColor
            } else {
                backgroundColor = WPStyleGuide.Notifications.blockBackgroundColor
            }
        }
    }
    
    // MARK: - Public Methods
    public func downloadImageWithURL(url: NSURL?) {
        if url == imageURL {
            return
        }

        let success = { (image: UIImage) in
            self.blockImageView.displayImageWithSpringAnimation(image)
        }
        
        blockImageView.downloadImage(url, placeholderName: nil, success: success, failure: nil)
        
        imageURL = url
    }
    
    // MARK: - View Methods
    public override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle  = .None
    }
    
    // MARK: - Private Methods

    
    // MARK: - Private
    private var imageURL:               NSURL?
    
    // MARK: - IBOutlets
    @IBOutlet weak var blockImageView:  UIImageView!
}
