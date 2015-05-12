import Foundation


@objc public class NoteBlockHeaderTableViewCell : NoteBlockTableViewCell
{
    // MARK: - Public Properties
    public var headerTitle: String? {
        set {
            headerTitleLabel.text  = newValue
        }
        get {
            return headerTitleLabel.text
        }
    }
    
    public var attributedHeaderTitle: NSAttributedString? {
        set {
            headerTitleLabel.attributedText  = newValue
        }
        get {
            return headerTitleLabel.attributedText
        }
    }

    public var headerDetails: String? {
        set {
            headerDetailsLabel.text = newValue
        }
        get {
            return headerDetailsLabel.text
        }
    }
    
    
    // MARK: - Public Methods
    public func downloadGravatarWithURL(url: NSURL?) {
        if url == gravatarURL {
            return
        }
        
        let placeholderImage = WPStyleGuide.Notifications.gravatarPlaceholderImage
        let success = { (image: UIImage) in
            self.gravatarImageView.displayImageWithFadeInAnimation(image)
        }

        gravatarImageView.downloadImage(url, placeholderImage: placeholderImage, success: success, failure: nil)
        
        gravatarURL = url
    }
    
    // MARK: - View Methods
    public override func awakeFromNib() {
        super.awakeFromNib()
        
        accessoryType                   = .DisclosureIndicator
        contentView.autoresizingMask    = .FlexibleHeight | .FlexibleWidth
        
        backgroundColor                 = WPStyleGuide.Notifications.blockBackgroundColor
        headerTitleLabel.font           = WPStyleGuide.Notifications.headerTitleBoldFont
        headerTitleLabel.textColor      = WPStyleGuide.Notifications.headerTitleColor
        headerDetailsLabel.font         = WPStyleGuide.Notifications.headerDetailsRegularFont
        headerDetailsLabel.textColor    = WPStyleGuide.Notifications.headerDetailsColor
        gravatarImageView.image         = WPStyleGuide.Notifications.gravatarPlaceholderImage!
        
        // iPad: Use a bigger image size!
        if UIDevice.isPad() {
            gravatarImageView.updateConstraint(.Height, constant: gravatarImageSizePad.width)
            gravatarImageView.updateConstraint(.Width,  constant: gravatarImageSizePad.height)
        }
    }
    
    // MARK: - Overriden Methods
    public override func refreshSeparators() {
        separatorsView.bottomVisible    = true
        separatorsView.bottomInsets     = UIEdgeInsetsZero
    }
    

    // MARK: - Private
    private let gravatarImageSizePad:               CGSize      = CGSize(width: 36.0, height: 36.0)
    private var gravatarURL:                        NSURL?
    
    // MARK: - IBOutlets
    @IBOutlet private weak var gravatarImageView:   UIImageView!
    @IBOutlet private weak var headerTitleLabel:    UILabel!
    @IBOutlet private weak var headerDetailsLabel:  UILabel!
}
