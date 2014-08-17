import Foundation


@objc public class NoteBlockUserTableViewCell : NoteBlockTableViewCell
{
    // MARK: - Public Properties
    public var name: String? {
        didSet {
            nameLabel.text  = name ?? String()
        }
    }
    public var blogURL: NSURL? {
        didSet {
            blogLabel.text  = blogURL?.host ?? String()
            accessoryType   = blogURL != nil ? .DisclosureIndicator : .None
        }
    }
    public var actionEnabled: Bool = false {
        didSet {
            followButton.hidden = !actionEnabled
        }
    }
    public var following: Bool = false {
        didSet {
            followButton.selected = following
        }
    }
    public var onFollowClick:   (() -> Void)?
    public var onUnfollowClick: (() -> Void)?
    
    // MARK - Public Methods
    public func downloadGravatarWithURL(url: NSURL?) {
        if url == gravatarURL {
            return
        }
    
        if let unwrappedURL = url {
            let placeholderImage = UIImage(named: Animation.placeholderName)
            
            gravatarImageView.downloadImage(unwrappedURL,
                placeholderImage: placeholderImage,
                success: displayImageWithAnimation,
                failure: nil
            )
        }
        
        gravatarURL = url
    }
    
    // MARK: - View Methods
    public override func awakeFromNib() {
        super.awakeFromNib()
        WPStyleGuide.configureFollowButton(followButton)

        backgroundColor                     = Notification.Colors.blockBackground
        nameLabel.textColor                 = Notification.Colors.blockHeader
        nameLabel.font                      = Notification.Fonts.blockHeader
        
        blogLabel.font                      = Notification.Fonts.blockSubtitle
        blogLabel.textColor                 = Notification.Colors.blockSubtitle
        blogLabel.adjustsFontSizeToFitWidth = false;
    }
    
    public override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        followButton.highlighted = false
    }

    public override func setHighlighted(highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        followButton.highlighted = false
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

    // MARK: - Button Delegates
    @IBAction public func followWasPressed(sender: DTLinkButton) {
        if let listener = onFollowClick {
            listener()
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
    @IBOutlet private weak var blogLabel:           UILabel!
    @IBOutlet private weak var gravatarImageView:   UIImageView!
    @IBOutlet private weak var followButton:        UIButton!
}
