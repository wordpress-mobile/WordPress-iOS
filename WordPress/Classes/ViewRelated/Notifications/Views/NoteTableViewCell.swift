import Foundation


@objc public class NoteTableViewCell : WPTableViewCell
{
    // MARK: - Public Properties
    public var read: Bool = false {
        didSet {
            refreshBackgrounds()
        }
    }
    public var attributedSubject: NSAttributedString? {
        didSet {
            subjectLabel.attributedText = attributedSubject ?? NSAttributedString()
            setNeedsLayout()
        }
    }
    public var attributedSnippet: NSAttributedString? {
        didSet {
            snippetLabel.attributedText = attributedSnippet ?? NSAttributedString()
            refreshNumberOfLines()
            setNeedsLayout()
        }
    }
    public var noticon: NSString? {
        didSet {
            noticonLabel.text = noticon ?? String()
        }
    }
    public var unapproved: Bool = false {
        didSet {
            refreshBackgrounds()
        }
    }
    
    // MARK: - Public Methods
    public func downloadGravatarWithURL(url: NSURL?) {
        if url == gravatarURL {
            return
        }
        
        // Scale down Gravatar images: faster downloads!
        if let unrawppedURL = url {
            let size                = iconImageView.frame.width * UIScreen.mainScreen().scale
            let scaledURL           = unrawppedURL.patchGravatarUrlWithSize(size)
            iconImageView.downloadImage(scaledURL, placeholderName: placeholderName)
        } else {
            iconImageView.image = UIImage(named: placeholderName)
        }
        
        gravatarURL = url
    }
 
    // MARK: - View Methods
    public override func awakeFromNib() {
        super.awakeFromNib()

        contentView.autoresizingMask    = .FlexibleHeight | .FlexibleWidth

        iconImageView.image             = UIImage(named: placeholderName)

        noticonContainerView.layer.cornerRadius = noticonContainerView.frame.size.width / 2

        noticonView.layer.cornerRadius  = noticonRadius
        noticonLabel.font               = Style.noticonFont
        noticonLabel.textColor          = Style.noticonTextColor
        
        subjectLabel.numberOfLines      = subjectNumberOfLinesWithSnippet
        subjectLabel.shadowOffset       = CGSizeZero

        snippetLabel.numberOfLines      = snippetNumberOfLines
    }
    
    public override func layoutSubviews() {
        refreshLabelPreferredMaxLayoutWidth()
        refreshBackgrounds()
        super.layoutSubviews()
    }

    public override func setSelected(selected: Bool, animated: Bool) {
        // Note: this is required, since the cell unhighlight mechanism will reset the new background color
        super.setSelected(selected, animated: animated)
        refreshBackgrounds()
    }
    
    public override func setHighlighted(highlighted: Bool, animated: Bool) {
        // Note: this is required, since the cell unhighlight mechanism will reset the new background color
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
        // Noticon Background
        if unapproved {
            noticonView.backgroundColor = Style.noticonUnmoderatedColor
            noticonContainerView.backgroundColor = Style.noticonTextColor
        } else if read {
            noticonView.backgroundColor = Style.noticonReadColor
            noticonContainerView.backgroundColor = Style.noticonTextColor
        } else {
            noticonView.backgroundColor = Style.noticonUnreadColor
            noticonContainerView.backgroundColor = Style.noteBackgroundUnreadColor
        }

        // Cell Background
        backgroundColor = read ? Style.noteBackgroundReadColor : Style.noteBackgroundUnreadColor
    }
    
    private func refreshNumberOfLines() {
        // When the snippet is present, let's clip the number of lines in the subject
        subjectLabel.numberOfLines = attributedSnippet != nil ? subjectNumberOfLinesWithSnippet : subjectNumberOfLinesWithoutSnippet
    }

    
    // MARK: - Private Alias
    private typealias Style = WPStyleGuide.Notifications
    
    // MARK: - Private Properties
    private let subjectPaddingRight:                CGFloat     = 12
    private let subjectNumberOfLinesWithoutSnippet: Int         = 3
    private let subjectNumberOfLinesWithSnippet:    Int         = 2
    private let snippetNumberOfLines:               Int         = 2
    private let noticonRadius:                      CGFloat     = 10
    private var placeholderName:                    String      = "gravatar"
    private var gravatarURL:                        NSURL?
    
    // MARK: - IBOutlets
    @IBOutlet private weak var iconImageView:           CircularImageView!
    @IBOutlet private weak var noticonLabel:            UILabel!
    @IBOutlet private weak var noticonContainerView:    UIView!
    @IBOutlet private weak var noticonView:             UIView!
    @IBOutlet private weak var subjectLabel:            UILabel!
    @IBOutlet private weak var snippetLabel:            UILabel!
    @IBOutlet private weak var timestampLabel:          UILabel!
}
