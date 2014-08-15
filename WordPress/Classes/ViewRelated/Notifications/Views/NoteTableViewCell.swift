import Foundation


@objc public class NoteTableViewCell : WPTableViewCell
{
    @IBOutlet private var iconImageView:    UIImageView!
    @IBOutlet private var noticonLabel:     UILabel!
    @IBOutlet private var noticonView:      UIView!
    @IBOutlet private var subjectLabel:     UILabel!
    @IBOutlet private var timestampLabel:   UILabel!
    
// FIXME: Cleanup
    private let SubjectPaddingRight:        CGFloat     = 2
    private let NumberOfLines:              NSInteger   = 0
    private let NoticonRadius:              CGFloat     = 10
    private let PlaceholderImageName                    = "gravatar"
    
    
    public var read:                Bool                = false {
        didSet {
            self.refreshBackgrounds()
        }
    }
    public var attributedSubject:   NSAttributedString! {
        didSet {
            subjectLabel.attributedText = attributedSubject
            self.setNeedsLayout()
        }
    }
    public var iconURL:             NSURL! {
        didSet {
            if !iconURL {
                return;
            }
            
            // If needed, patch gravatar URL's with the required size. This will help us minimize bandwith usage
            let size: CGFloat            = CGRectGetWidth(self.iconImageView.frame) * UIScreen.mainScreen().scale
            let scaledURL: NSURL        = iconURL.patchGravatarUrlWithSize(size)
            let placeholder: UIImage    = UIImage(named: PlaceholderImageName)
            iconImageView.setImageWithURL(scaledURL, placeholderImage: placeholder)
        }
    }
    public var noticon:             NSString! {
        didSet {
            noticonLabel.text = noticon
        }
    }
    public var timestamp:           NSDate! {
        didSet {
            timestampLabel.text = timestamp.shortString()
        }
    }
 
    
    public override func awakeFromNib() {
        
        super.awakeFromNib()
        
        assert(iconImageView)
        assert(noticonLabel)
        assert(noticonView)
        assert(subjectLabel)
        assert(timestampLabel)
        
        noticonView.layer.cornerRadius     = NoticonRadius
        noticonLabel.font                  = NotificationFonts.noticon
        noticonLabel.textColor             = UIColor.whiteColor()
        
        subjectLabel.numberOfLines         = NumberOfLines
        subjectLabel.backgroundColor       = UIColor.clearColor()
        subjectLabel.textAlignment         = .Left
        subjectLabel.lineBreakMode         = .ByWordWrapping
        subjectLabel.shadowOffset          = CGSizeZero
        subjectLabel.textColor             = WPStyleGuide.littleEddieGrey()
        
        timestampLabel.textAlignment       = .Right;
        timestampLabel.font                = NotificationFonts.timestamp
        timestampLabel.textColor           = NotificationColors.timestamp
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        contentView.layoutIfNeeded()
        refreshLabelPreferredMaxLayoutWidth()
    }

    private func refreshLabelPreferredMaxLayoutWidth() {
        let width = CGRectGetMinX(timestampLabel.frame) - SubjectPaddingRight - CGRectGetMinX(subjectLabel.frame);
        subjectLabel.preferredMaxLayoutWidth = width;
    }

    
    public override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        refreshBackgrounds()
    }
    
    public override func setHighlighted(highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        refreshBackgrounds()
    }
    
    
    private func refreshBackgrounds() {
        if read {
            noticonView.backgroundColor = NotificationColors.iconRead
            backgroundColor             = NotificationColors.backgroundRead
        } else {
            noticonView.backgroundColor = NotificationColors.iconUnread
            backgroundColor             = NotificationColors.backgroundUnread
        }
    }
}
