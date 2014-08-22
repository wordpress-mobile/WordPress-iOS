import Foundation


@objc public class NoteBlockUserTableViewCell : NoteBlockTableViewCell
{
    public typealias EventHandler = (() -> Void)
    
    // MARK: - Public Properties
    public var onFollowClick:      EventHandler?
    public var onUnfollowClick:    EventHandler?
    
    public var isFollowEnabled: Bool = false {
        didSet {
            btnFollow.enabled = isFollowEnabled
        }
    }
    public var isFollowOn: Bool = false {
        didSet {
            btnFollow.selected = isFollowOn
        }
    }
    
    public var name: String? {
        didSet {
            nameLabel.text  = name != nil ? name! : String()
        }
    }
    public var blogTitle: String? {
        didSet {
            blogLabel.text  = blogTitle != nil ? blogTitle! :  String()
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

        WPStyleGuide.configureFollowButton(btnFollow)
        
        backgroundColor                     = Notification.Colors.blockBackground
        accessoryType                       = .None
        
        nameLabel.textColor                 = Notification.Colors.blockHeader
        nameLabel.font                      = Notification.Fonts.blockHeader
        
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
    
    // MARK: - IBActions
    @IBAction public func followWasPressed(sender: AnyObject) {
        if let listener = isFollowOn ? onUnfollowClick : onFollowClick {
            listener()
        }
        isFollowOn = !isFollowOn
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
    @IBOutlet private weak var blogLabel:           UILabel!
    @IBOutlet private weak var btnFollow:           UIButton!
    @IBOutlet private weak var gravatarImageView:   UIImageView!
}
