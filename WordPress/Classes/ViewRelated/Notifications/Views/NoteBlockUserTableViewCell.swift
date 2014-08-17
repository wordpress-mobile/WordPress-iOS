import Foundation


@objc public class NoteBlockUserTableViewCell : NoteBlockTableViewCell
{
    // MARK: - Public Properties
    public var name: String? {
        didSet {
            nameLabel.text  = name ?? String()
        }
    }
    public var blogURL: String? {
        didSet {
            blogLabel.text  = blogURL ?? String()
        }
    }
    
    // MARK: - Public Methods
    public func downloadGravatarWithURL(url: NSURL?) {
        if url == gravatarURL {
            return
        }
    
        let placeholderImage = UIImage(named: Animation.placeholderName)
        if let unwrappedURL = url {
            gravatarImageView.downloadImage(unwrappedURL, placeholderImage: placeholderImage, success: displayImageWithAnimation, failure: nil)
        } else {
            gravatarImageView.image = placeholderImage
        }
        
        gravatarURL = url
    }
    
    // MARK: - View Methods
    public override func awakeFromNib() {
        super.awakeFromNib()

        backgroundColor                     = Notification.Colors.blockBackground
        accessoryType                       = .None
        
        nameLabel.textColor                 = Notification.Colors.blockHeader
        nameLabel.font                      = Notification.Fonts.blockHeader
        
        taglineLabel.font                   = Notification.Fonts.blockHeader
        taglineLabel.textColor              = Notification.Colors.blockHeader
        
        blogLabel.font                      = Notification.Fonts.blockSubtitle
        blogLabel.textColor                 = Notification.Colors.blockSubtitle
        blogLabel.adjustsFontSizeToFitWidth = false;
    }
    
    // MARK: - Private Helpers
    private func displayImageWithAnimation(image: UIImage) {
        gravatarImageView.image    = image;
        gravatarImageView.alpha    = Animation.alphaInitial
        
        UIView.animateWithDuration(Animation.duration) { [weak self] in
            if let imageView = self?.gravatarImageView {
                imageView.alpha = Animation.alphaFinal
            }
        }
    }
    
    // MARK: - Private
    private struct Animation {
        static let duration         = 0.3
        static let alphaInitial     = CGFloat(0.5)
        static let alphaFinal       = CGFloat(1.0)
        static let placeholderName  = "gravatar"
    }
    private var gravatarURL: NSURL?
    
    // MARK: - IBOutlets
    @IBOutlet private weak var nameLabel:           UILabel!
    @IBOutlet private weak var taglineLabel:        UILabel!
    @IBOutlet private weak var blogLabel:           UILabel!
    @IBOutlet private weak var gravatarImageView:   UIImageView!
}
