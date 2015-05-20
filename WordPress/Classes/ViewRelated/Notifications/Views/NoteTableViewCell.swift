import Foundation


@objc public class NoteTableViewCell : WPTableViewCell
{
    // MARK: - Public Properties
    public var read: Bool = false {
        didSet {
            if read != oldValue {
                refreshBackgrounds()
            }
        }
    }
    public var unapproved: Bool = false {
        didSet {
            if unapproved != oldValue {
                refreshBackgrounds()
            }
        }
    }
    public var showsSeparator: Bool {
        set {
            separatorView.hidden = !newValue
        }
        get {
            return separatorView.hidden == false
        }
    }
    public var attributedSubject: NSAttributedString? {
        set {
            subjectLabel.attributedText = newValue
            setNeedsLayout()
        }
        get {
            return subjectLabel.attributedText
        }
    }
    public var attributedSnippet: NSAttributedString? {
        set {
            snippetLabel.attributedText = newValue
            refreshNumberOfLines()
            setNeedsLayout()
        }
        get {
            return snippetLabel.attributedText
        }
    }
    public var noticon: String? {
        set {
            noticonLabel.text = newValue
        }
        get {
            return noticonLabel.text
        }
    }
    
    // MARK: - Public Methods
    public class func reuseIdentifier() -> String {
        return classNameWithoutNamespaces()
    }
    
    public func downloadGravatarWithURL(url: NSURL?) {
        if url == gravatarURL {
            return
        }

        let placeholderImage = WPStyleGuide.Notifications.gravatarPlaceholderImage
        
        // Scale down Gravatar images: faster downloads!
        if let unrawppedURL = url {
            let size                = iconImageView.frame.width * UIScreen.mainScreen().scale
            let scaledURL           = unrawppedURL.patchGravatarUrlWithSize(size)
            iconImageView.downloadImage(scaledURL, placeholderImage: placeholderImage)
        } else {
            iconImageView.image     = placeholderImage
        }
        
        gravatarURL = url
    }
 
    
    // MARK: - View Methods
    public override func awakeFromNib() {
        super.awakeFromNib()

        contentView.autoresizingMask    = .FlexibleHeight | .FlexibleWidth

        iconImageView.image             = WPStyleGuide.Notifications.gravatarPlaceholderImage

        noticonContainerView.layer.cornerRadius = noticonContainerView.frame.size.width / 2

        noticonView.layer.cornerRadius  = Settings.noticonRadius
        noticonLabel.font               = Style.noticonFont
        noticonLabel.textColor          = Style.noticonTextColor
        
        subjectLabel.numberOfLines      = Settings.subjectNumberOfLinesWithSnippet
        subjectLabel.shadowOffset       = CGSizeZero

        snippetLabel.numberOfLines      = Settings.snippetNumberOfLines
        
        // Separator: Make sure the height is 1pixel, not 1point
        let separatorHeightInPixels     = Settings.separatorHeight / UIScreen.mainScreen().scale
        separatorView.updateConstraint(.Height, constant: separatorHeightInPixels)
        separatorView.backgroundColor   = WPStyleGuide.Notifications.noteSeparatorColor
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
        let maxWidthLabel                    = frame.width - Settings.textInsets.right - subjectLabel.frame.minX
        subjectLabel.preferredMaxLayoutWidth = maxWidthLabel
        snippetLabel.preferredMaxLayoutWidth = maxWidthLabel
    }
    
    private func refreshBackgrounds() {
        // Noticon Background
        if unapproved {
            noticonView.backgroundColor             = Style.noticonUnmoderatedColor
            noticonContainerView.backgroundColor    = Style.noticonTextColor
        } else if read {
            noticonView.backgroundColor             = Style.noticonReadColor
            noticonContainerView.backgroundColor    = Style.noticonTextColor
        } else {
            noticonView.backgroundColor             = Style.noticonUnreadColor
            noticonContainerView.backgroundColor    = Style.noteBackgroundUnreadColor
        }

        // Cell Background: Assign only if needed, for performance
        let newBackgroundColor  = read ? Style.noteBackgroundReadColor : Style.noteBackgroundUnreadColor
        if backgroundColor != newBackgroundColor {
            backgroundColor = newBackgroundColor
        }
    }
    
    private func refreshNumberOfLines() {
        // When the snippet is present, let's clip the number of lines in the subject
        let showsSnippet = attributedSnippet != nil
        subjectLabel.numberOfLines =  Settings.subjectNumberOfLines(showsSnippet)
    }

    public class func layoutHeightWithWidth(width: CGFloat, subject: NSAttributedString?, snippet: NSAttributedString?) -> CGFloat {
        
        // Limit the width (iPad Devices)
        let cellWidth               = min(width, Style.maximumCellWidth)
        var cellHeight              = Settings.textInsets.top + Settings.textInsets.bottom
        
        // Calculate the maximum label size
        let maxLabelWidth           = cellWidth - Settings.textInsets.left - Settings.textInsets.right
        let maxLabelSize            = CGSize(width: maxLabelWidth, height: CGFloat.max)
        
        // Helpers
        let showsSnippet            = snippet != nil
        
        // If we must render a snippet, the maximum subject height will change. Account for that please
        if let unwrappedSubject = subject {
            let subjectRect         = unwrappedSubject.boundingRectWithSize(maxLabelSize,
                                        options: .UsesLineFragmentOrigin,
                                        context: nil)
            
            cellHeight              += min(subjectRect.height, Settings.subjectMaximumHeight(showsSnippet))
        }
        
        if let unwrappedSubject = snippet {
            let snippetRect         = unwrappedSubject.boundingRectWithSize(maxLabelSize,
                                        options: .UsesLineFragmentOrigin,
                                        context: nil)
            
            cellHeight              += min(snippetRect.height, Settings.snippetMaximumHeight())
        }
        
        return max(cellHeight, Settings.minimumCellHeight)
    }
    
    
    // MARK: - Private Alias
    private typealias Style = WPStyleGuide.Notifications
    
    // MARK: - Private Settings
    private struct Settings {
        static let minimumCellHeight:                   CGFloat         = 70
        static let separatorHeight:                     CGFloat         = 1
        static let textInsets:                          UIEdgeInsets    = UIEdgeInsets(top: 9, left: 71, bottom: 12, right: 12)
        static let subjectNumberOfLinesWithoutSnippet:  Int             = 3
        static let subjectNumberOfLinesWithSnippet:     Int             = 2
        static let snippetNumberOfLines:                Int             = 2
        static let noticonRadius:                       CGFloat         = 10
        
        static func subjectNumberOfLines(showsSnippet: Bool) -> Int {
            return showsSnippet ? subjectNumberOfLinesWithSnippet : subjectNumberOfLinesWithoutSnippet
        }

        static func subjectMaximumHeight(showsSnippet: Bool) -> CGFloat {
            return CGFloat(Settings.subjectNumberOfLines(showsSnippet)) * Style.subjectLineSize
        }
        
        static func snippetMaximumHeight() -> CGFloat {
            return CGFloat(snippetNumberOfLines) * Style.snippetLineSize
        }
    }

    // MARK: - Private Properties
    private var gravatarURL:                            NSURL?
    
    // MARK: - IBOutlets
    @IBOutlet private weak var iconImageView:           CircularImageView!
    @IBOutlet private weak var noticonLabel:            UILabel!
    @IBOutlet private weak var noticonContainerView:    UIView!
    @IBOutlet private weak var noticonView:             UIView!
    @IBOutlet private weak var subjectLabel:            UILabel!
    @IBOutlet private weak var snippetLabel:            UILabel!
    @IBOutlet private weak var timestampLabel:          UILabel!
    @IBOutlet private weak var separatorView:           UIView!
}
