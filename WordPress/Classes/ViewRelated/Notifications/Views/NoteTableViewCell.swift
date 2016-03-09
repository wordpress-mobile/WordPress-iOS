import Foundation
import WordPressShared

/**
*  @class       NoteTableViewCell
*  @brief       The purpose of this class is to render a Notification entity, onscreen.
*  @details     This cell should be loaded from its nib, since the autolayout constraints and outlets are not
*               generated via code.
*               Supports specific styles for Unapproved Comment Notifications, Unread Notifications, and a brand
*               new "Undo Deletion" mechanism has been implemented. See "NoteUndoOverlayView" for reference.
*/

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
    public var markedForDeletion: Bool = false {
        didSet {
            if markedForDeletion != oldValue {
                refreshSubviewVisibility()
                refreshBackgrounds()
                refreshUndoOverlay()
            }
        }
    }
    public var showsBottomSeparator: Bool {
        set {
            separatorsView.bottomVisible = newValue
        }
        get {
            return separatorsView.bottomVisible == false
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
    public var onUndelete: (Void -> Void)?
    
    
    
    // MARK: - Public Methods
    public class func reuseIdentifier() -> String {
        return classNameWithoutNamespaces()
    }

    public func downloadIconWithURL(url: NSURL?) {
        let isGravatarURL = url.map { Gravatar.isGravatarURL($0) } ?? false
        if isGravatarURL {
            downloadGravatarWithURL(url)
            return
        }
        
        // Handle non-gravatar images
        let placeholderImage = Style.blockGravatarPlaceholderImage(isApproved: !unapproved)
        iconImageView.downloadImage(url, placeholderImage: placeholderImage, success: nil, failure: { (error) in
            // Note: Don't cache 404's. Otherwise Unapproved / Approved gravatars won't switch!
            if self.gravatarURL?.isEqual(url) == true {
                self.gravatarURL = nil
            }
        })
        
        gravatarURL = url
    }
    
    
    // MARK: - Gravatar Helpers
    private func downloadGravatarWithURL(url: NSURL?) {
        if url == gravatarURL {
            return
        }

        let placeholderImage = Style.blockGravatarPlaceholderImage(isApproved: !unapproved)
        let gravatar = url.flatMap { Gravatar($0) }
        
        if gravatar == nil {
            // Note: If we've got any issues with the Gravatar instance, fallback to the placeholder, and dont'
            // cache the URL!
            iconImageView.image = placeholderImage
            gravatarURL = nil
            return
        }
        
        iconImageView.downloadGravatar(gravatar,
            placeholder: placeholderImage,
            animate: false,
            failure: { (error: NSError!) in
                // Note: Don't cache 404's. Otherwise Unapproved / Approved gravatars won't switch!
                if self.gravatarURL?.isEqual(url) == true {
                    self.gravatarURL = nil
                }
        })

        gravatarURL = url
    }
 
    
    
    // MARK: - UITableViewCell Methods
    public override func awakeFromNib() {
        super.awakeFromNib()

        contentView.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]

        iconImageView.image             = WPStyleGuide.Notifications.gravatarPlaceholderImage

        noticonContainerView.layer.cornerRadius = noticonContainerView.frame.size.width / 2

        noticonView.layer.cornerRadius  = Settings.noticonRadius
        noticonLabel.font               = Style.noticonFont
        noticonLabel.textColor          = Style.noticonTextColor
        
        subjectLabel.numberOfLines      = Settings.subjectNumberOfLinesWithSnippet
        subjectLabel.shadowOffset       = CGSizeZero

        snippetLabel.numberOfLines      = Settings.snippetNumberOfLines
        
        // Separators: Setup bottom separators!
        separatorsView.bottomColor      = WPStyleGuide.Notifications.noteSeparatorColor
        separatorsView.bottomInsets     = Settings.separatorInsets
        backgroundView                  = separatorsView
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
        let newBackgroundColor = read ? Style.noteBackgroundReadColor : Style.noteBackgroundUnreadColor

        if backgroundColor != newBackgroundColor {
            backgroundColor = newBackgroundColor
        }
    }
    
    private func refreshSubviewVisibility() {
        for subview in contentView.subviews {
            subview.hidden = markedForDeletion
        }
    }
    
    private func refreshNumberOfLines() {
        // When the snippet is present, let's clip the number of lines in the subject
        let showsSnippet = attributedSnippet != nil
        subjectLabel.numberOfLines =  Settings.subjectNumberOfLines(showsSnippet)
    }
    
    private func refreshUndoOverlay() {
        // Remove
        if markedForDeletion == false {
            undoOverlayView?.removeFromSuperview()
            return
        }
        
        // Load
        if undoOverlayView == nil {
            let nibName = NoteUndoOverlayView.classNameWithoutNamespaces()
            NSBundle.mainBundle().loadNibNamed(nibName, owner: self, options: nil)
            undoOverlayView.translatesAutoresizingMaskIntoConstraints = false
        }

        // Attach
        if undoOverlayView.superview == nil {
            contentView.addSubview(undoOverlayView)
            contentView.pinSubviewToAllEdges(undoOverlayView)
        }
    }

    
    
    // MARK: - Public Static Helpers
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
    
    
    
    // MARK: - Action Handlers
    @IBAction public func undeleteWasPressed(sender: AnyObject) {
        onUndelete?()
    }
    
    
    
    // MARK: - Private Alias
    private typealias Style = WPStyleGuide.Notifications
    
    // MARK: - Private Settings
    private struct Settings {
        static let minimumCellHeight                    = CGFloat(70)
        static let textInsets                           = UIEdgeInsets(top: 9.0, left: 71.0, bottom: 12.0, right: 12.0)
        static let separatorInsets                      = UIEdgeInsets(top: 0.0, left: 12.0, bottom: 0.0, right: 0.0)
        static let subjectNumberOfLinesWithoutSnippet   = 3
        static let subjectNumberOfLinesWithSnippet      = 2
        static let snippetNumberOfLines                 = 2
        static let noticonRadius                        = CGFloat(10)
        
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
    private var gravatarURL : NSURL?
    private var separatorsView = SeparatorsView()
    
    // MARK: - IBOutlets
    @IBOutlet private weak var iconImageView:           CircularImageView!
    @IBOutlet private weak var noticonLabel:            UILabel!
    @IBOutlet private weak var noticonContainerView:    UIView!
    @IBOutlet private weak var noticonView:             UIView!
    @IBOutlet private weak var subjectLabel:            UILabel!
    @IBOutlet private weak var snippetLabel:            UILabel!
    @IBOutlet private weak var timestampLabel:          UILabel!
    
    // MARK: - Undo Overlay Optional
    @IBOutlet private var undoOverlayView:              NoteUndoOverlayView!
}
