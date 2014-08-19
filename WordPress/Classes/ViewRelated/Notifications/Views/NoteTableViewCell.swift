import Foundation


@objc public class NoteTableViewCell : WPTableViewCell
{
    // MARK: - Public Properties
    public var read: Bool = false {
        didSet {
            backgroundColor = read ? Notification.Colors.backgroundRead : Notification.Colors.backgroundUnread
        }
    }
    public var attributedSubject: NSAttributedString? {
        didSet {
            subjectLabel.attributedText = attributedSubject ?? NSAttributedString()
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
        noticonLabel.font               = Notification.Fonts.noticon
        noticonLabel.textColor          = UIColor.whiteColor()
        
        subjectLabel.numberOfLines      = numberOfLines
        subjectLabel.backgroundColor    = UIColor.clearColor()
        subjectLabel.textAlignment      = .Left
        subjectLabel.lineBreakMode      = .ByWordWrapping
        subjectLabel.shadowOffset       = CGSizeZero
        subjectLabel.textColor          = Notification.Colors.blockText
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        contentView.layoutIfNeeded()
        refreshLabelPreferredMaxLayoutWidth()
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
        subjectLabel.preferredMaxLayoutWidth = bounds.width - subjectPaddingRight - subjectLabel.frame.minX;
    }
    
    private func refreshBackgrounds() {
        noticonView.backgroundColor = read ? Notification.Colors.iconRead : Notification.Colors.iconUnread
    }
    
    // MARK: - Private Properties
    private let subjectPaddingRight:            CGFloat     = 12
    private let numberOfLines:                  Int         = 0
    private let noticonRadius:                  CGFloat     = 10
    private var placeholderName:                String      = "gravatar"
    private var gravatarURL:                    NSURL?
    
    // MARK: - IBOutlets
    @IBOutlet private weak var iconImageView:   UIImageView!
    @IBOutlet private weak var noticonLabel:    UILabel!
    @IBOutlet private weak var noticonView:     UIView!
    @IBOutlet private weak var subjectLabel:    UILabel!
    @IBOutlet private weak var timestampLabel:  UILabel!
}
