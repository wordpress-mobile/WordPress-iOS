import Foundation


@objc public class NoteTableViewCell : WPTableViewCell
{
    // MARK: - Public Properties
    public var read: Bool = false {
        didSet {
            backgroundColor = read ? WPStyleGuide.Notifications.Colors.backgroundRead : WPStyleGuide.Notifications.Colors.backgroundUnread
        }
    }
    public var attributedSubject: NSAttributedString? {
        didSet {
            subjectLabel.attributedText = attributedSubject != nil ? attributedSubject! : NSAttributedString()
            setNeedsLayout()
        }
    }
    public var attributedSnippet: NSAttributedString? {
        didSet {
            snippetLabel.attributedText = attributedSnippet != nil ? attributedSnippet! : NSAttributedString()
            setNeedsLayout()
        }
    }
    public var noticon: NSString? {
        didSet {
            noticonLabel.text = noticon ?? String()
        }
    }
    
    // MARK: - Public Methods
    public func downloadGravatarWithURL(url: NSURL?) {
        if url == gravatarURL {
            return
        }

        let placeholderImage = UIImage(named: placeholderName)
        if let unrawppedURL = url {
            let size                = iconImageView.frame.width * UIScreen.mainScreen().scale
            let scaledURL           = unrawppedURL.patchGravatarUrlWithSize(size)
            iconImageView.downloadImage(scaledURL, placeholderImage: placeholderImage)
        } else {
            iconImageView.image = placeholderImage
        }
        
        gravatarURL = url
    }
 
    // MARK: - View Methods
    public override func awakeFromNib() {
        super.awakeFromNib()
        
        iconImageView.image             = UIImage(named: placeholderName)
        
        noticonView.layer.cornerRadius  = noticonRadius
        noticonLabel.font               = WPStyleGuide.Notifications.Fonts.noticon
        noticonLabel.textColor          = UIColor.whiteColor()
        
        subjectLabel.numberOfLines      = subjectNumberOfLines
        subjectLabel.backgroundColor    = UIColor.clearColor()
        subjectLabel.textAlignment      = .Left
        subjectLabel.lineBreakMode      = .ByWordWrapping
        subjectLabel.shadowOffset       = CGSizeZero
        subjectLabel.textColor          = WPStyleGuide.Notifications.Colors.blockText

        snippetLabel.backgroundColor    = UIColor.clearColor()
        snippetLabel.lineBreakMode      = .ByWordWrapping
        snippetLabel.numberOfLines      = snippetNumberOfLines
    }
    
    public override func layoutSubviews() {
        refreshLabelPreferredMaxLayoutWidth()
        super.layoutSubviews()
        contentView.layoutIfNeeded()
    }

    public override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        refreshBackgrounds()
    }
    
    public override func setHighlighted(highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        refreshBackgrounds()
    }
    
    // MARK: - Private Methods
    private func refreshLabelPreferredMaxLayoutWidth() {
        let maxWidthLabel                    = frame.width - subjectPaddingRight - subjectLabel.frame.minX
        subjectLabel.preferredMaxLayoutWidth = maxWidthLabel
        snippetLabel.preferredMaxLayoutWidth = maxWidthLabel
    }
    
    private func refreshBackgrounds() {
        noticonView.backgroundColor = read ? WPStyleGuide.Notifications.Colors.iconRead : WPStyleGuide.Notifications.Colors.iconUnread
    }
    
    // MARK: - Private Properties
    private let subjectPaddingRight:            CGFloat     = 12
    private let subjectNumberOfLines:           Int         = 0
    private let snippetNumberOfLines:           Int         = 2
    private let noticonRadius:                  CGFloat     = 10
    private var placeholderName:                String      = "gravatar"
    private var gravatarURL:                    NSURL?
    
    // MARK: - IBOutlets
    @IBOutlet private weak var iconImageView:   UIImageView!
    @IBOutlet private weak var noticonLabel:    UILabel!
    @IBOutlet private weak var noticonView:     UIView!
    @IBOutlet private weak var subjectLabel:    UILabel!
    @IBOutlet private weak var snippetLabel:    UILabel!
    @IBOutlet private weak var timestampLabel:  UILabel!
}
