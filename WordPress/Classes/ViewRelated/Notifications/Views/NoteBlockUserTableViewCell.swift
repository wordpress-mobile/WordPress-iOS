import Foundation


@objc public class NoteBlockUserTableViewCell : NoteBlockTableViewCell
{
    // MARK: IBOutlets
    @IBOutlet private weak var nameLabel:           UILabel!
    @IBOutlet private weak var blogLabel:           UILabel!
    @IBOutlet private weak var gravatarImageView:   UIImageView!
    @IBOutlet private weak var followButton:        UIButton!
    
    // MARK: Private
    private struct Animation {
        static let duration:                        NSTimeInterval  = 0.3
        static let alphaInitial:                    CGFloat         = 0.5
        static let alphaFinal:                      CGFloat         = 1.0
        static let placeholderName:                 String          = "gravatar"
    }
    
    // MARK: Public Properties
    public var name: String! {
        willSet {
            self.nameLabel.text = newValue
        }
    }
    
    public var blogURL: NSURL! {
        willSet {
            blogLabel.text  = newValue ? newValue.host : String()
            accessoryType   = newValue ? .DisclosureIndicator : .None
        }
    }
    public var gravatarURL: NSURL! {
        willSet {
            downloadImage(newValue)
        }
    }
    public var actionEnabled: Bool = false {
        willSet {
            followButton.hidden = !newValue
        }
    }
    public var following: Bool = false {
        willSet {
            followButton.selected = newValue
        }
    }
    public var onFollowClick: (() -> Void)?

    
    // MARK: Overriden Methods
    public override func awakeFromNib() {
        super.awakeFromNib()
        WPStyleGuide.configureFollowButton(followButton)

        backgroundColor                     = WPStyleGuide.Notifications.blockBackgroundColor()
        nameLabel.textColor                 = WPStyleGuide.littleEddieGrey();
        nameLabel.font                      = WPStyleGuide.tableviewSectionHeaderFont();
        
        blogLabel.font                      = WPStyleGuide.subtitleFont();
        blogLabel.textColor                 = WPStyleGuide.baseDarkerBlue();
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
    
    // MARK: Private Helpers
    private func downloadImage(url: NSURL!) {
        let request                     = NSMutableURLRequest(URL: url)
        request.HTTPShouldHandleCookies = false
        request.addValue("image/*", forHTTPHeaderField: "Accept")
        
        let placeholder = UIImage(named: Animation.placeholderName)
        
        gravatarImageView.setImageWithURLRequest(
            request,
            placeholderImage: placeholder,
            success: {
// FIXME: Uncomment when the compiler is fixed
//                [weak self]
                (request: NSURLRequest!, response: NSHTTPURLResponse!, image: UIImage!) -> Void in
                self.displayImage(image)
            },
            failure: nil)
    }
    
    private func displayImage(image: UIImage!) {
        if !image {
            return;
        }
        
        gravatarImageView.image    = image;
        gravatarImageView.alpha    = Animation.alphaInitial

        UIView.animateWithDuration(Animation.duration) {
// FIXME: Uncomment when the compiler is fixed
//                [weak self]
            () -> (Void) in
            self.gravatarImageView.alpha = Animation.alphaFinal
        }
    }

    
    // MARK: Button Delegates
    @IBAction public func followWasPressed(sender: DTLinkButton) {
        if let listener = onFollowClick {
            listener()
        }
    }
}
