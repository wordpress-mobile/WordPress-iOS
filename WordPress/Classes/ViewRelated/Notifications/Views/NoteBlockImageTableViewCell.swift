import Foundation


@objc public class NoteBlockImageTableViewCell : NoteBlockTableViewCell
{
    // MARK: - Public Properties
    public override var isBadge: Bool {
        didSet {
            backgroundColor = isBadge ? Styles.badgeBackgroundColor : Styles.blockBackgroundColor
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
        
        blockImageView.downloadImage(url, placeholderImage: nil, success: success, failure: nil)
        
        imageURL = url
    }
    
    // MARK: - View Methods
    public override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle  = .None
    }
    
    // MARK: - Private
    private var imageURL:               NSURL?
    
    // MARK: - Helpers
    private typealias Styles = WPStyleGuide.Notifications
    
    // MARK: - IBOutlets
    @IBOutlet weak var blockImageView:  UIImageView!
}
