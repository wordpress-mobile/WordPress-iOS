import Foundation


@objc public class NoteTableViewCell : WPTableViewCell
{
    // MARK - Public Properties
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
    public var timestamp: NSDate? {
        didSet {
            timestampLabel.text = timestamp?.shortString() ?? String()
        }
    }
    
    // MARK - Public Methods
    public func downloadGravatarWithURL(url: NSURL?) {
        if url == gravatarURL {
            return
        }
        
        if let unrawppedURL = url {
            let size                = iconImageView.frame.width * UIScreen.mainScreen().scale
            let scaledURL           = unrawppedURL.patchGravatarUrlWithSize(size)
            let placeholderImage    = UIImage(named: placeholderName)
            iconImageView.setImageWithURL(scaledURL, placeholderImage: placeholderImage)
        }
        
        gravatarURL = url
    }
 
    // MARK - View Methods
    public override func awakeFromNib() {
        super.awakeFromNib()
        
        assert(iconImageView)
        assert(noticonLabel)
        assert(noticonView)
        assert(subjectLabel)
        assert(timestampLabel)
        
        noticonView.layer.cornerRadius  = noticonRadius
        noticonLabel.font               = Notification.Fonts.noticon
        noticonLabel.textColor          = UIColor.whiteColor()
        
        subjectLabel.numberOfLines      = numberOfLines
        subjectLabel.backgroundColor    = UIColor.clearColor()
        subjectLabel.textAlignment      = .Left
        subjectLabel.lineBreakMode      = .ByWordWrapping
        subjectLabel.shadowOffset       = CGSizeZero
        subjectLabel.textColor          = Notification.Colors.blockText
        
        timestampLabel.textAlignment    = .Right;
        timestampLabel.font             = Notification.Fonts.timestamp
        timestampLabel.textColor        = Notification.Colors.timestamp
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
    
    // MARK - Private Methods
    private func refreshLabelPreferredMaxLayoutWidth() {
        subjectLabel.preferredMaxLayoutWidth = timestampLabel.frame.minX - timestampPaddingLeft - subjectLabel.frame.minX;
    }
    
    private func refreshBackgrounds() {
        noticonView.backgroundColor = read ? Notification.Colors.iconRead : Notification.Colors.iconUnread
    }
    
    // MARK - Private Properties
    private let timestampPaddingLeft:           CGFloat     = 2
    private let numberOfLines:                  Int         = 0
    private let noticonRadius:                  CGFloat     = 10
    private let placeholderName:                String      = "gravatar"
    private var gravatarURL:                    NSURL?
    
    // MARK - IBOutlets
    @IBOutlet private weak var iconImageView:   UIImageView!
    @IBOutlet private weak var noticonLabel:    UILabel!
    @IBOutlet private weak var noticonView:     UIView!
    @IBOutlet private weak var subjectLabel:    UILabel!
    @IBOutlet private weak var timestampLabel:  UILabel!
}
