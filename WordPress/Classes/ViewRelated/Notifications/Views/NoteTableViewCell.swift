import Foundation
import WordPressShared

/// The purpose of this class is to render a Notification entity, onscreen.
/// This cell should be loaded from its nib, since the autolayout constraints and outlets are not generated
/// via code.
/// Supports specific styles for Unapproved Comment Notifications, Unread Notifications, and a brand
/// new "Undo Deletion" mechanism has been implemented. See "NoteUndoOverlayView" for reference.
///
class NoteTableViewCell: WPTableViewCell
{
    // MARK: - Public Properties
    var read: Bool = false {
        didSet {
            if read != oldValue {
                refreshBackgrounds()
            }
        }
    }
    var unapproved: Bool = false {
        didSet {
            if unapproved != oldValue {
                refreshBackgrounds()
            }
        }
    }
    var markedForDeletion: Bool = false {
        didSet {
            if markedForDeletion != oldValue {
                refreshSubviewVisibility()
                refreshBackgrounds()
                refreshUndoOverlay()
            }
        }
    }
    var showsBottomSeparator: Bool {
        set {
            separatorsView.bottomVisible = newValue
        }
        get {
            return separatorsView.bottomVisible == false
        }
    }
    var attributedSubject: NSAttributedString? {
        set {
            subjectLabel.attributedText = newValue
            setNeedsLayout()
        }
        get {
            return subjectLabel.attributedText
        }
    }
    var attributedSnippet: NSAttributedString? {
        set {
            snippetLabel.attributedText = newValue
            refreshNumberOfLines()
            setNeedsLayout()
        }
        get {
            return snippetLabel.attributedText
        }
    }
    var noticon: String? {
        set {
            noticonLabel.text = newValue
        }
        get {
            return noticonLabel.text
        }
    }
    override var backgroundColor: UIColor? {
        didSet {
            // Note: This is done to improve scrolling performance!
            snippetLabel.backgroundColor = backgroundColor
            subjectLabel.backgroundColor = backgroundColor
            separatorsView.backgroundColor = backgroundColor
        }
    }
    var onUndelete: (() -> Void)?



    // MARK: - Public Methods
    class func reuseIdentifier() -> String {
        return classNameWithoutNamespaces()
    }

    func downloadIconWithURL(url: NSURL?) {
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
    override func awakeFromNib() {
        super.awakeFromNib()

        contentView.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]

        iconImageView.image = WPStyleGuide.Notifications.gravatarPlaceholderImage

        noticonContainerView.layer.cornerRadius = noticonContainerView.frame.size.width / 2

        noticonView.layer.cornerRadius = Settings.noticonRadius
        noticonLabel.font = Style.noticonFont
        noticonLabel.textColor = Style.noticonTextColor

        subjectLabel.numberOfLines = Settings.subjectNumberOfLinesWithSnippet
        subjectLabel.shadowOffset = CGSizeZero

        snippetLabel.numberOfLines = Settings.snippetNumberOfLines

        // Separators: Setup bottom separators!
        separatorsView.bottomColor = WPStyleGuide.Notifications.noteSeparatorColor
        separatorsView.bottomInsets = Settings.separatorInsets
        backgroundView = separatorsView
    }

    override func layoutSubviews() {
        refreshBackgrounds()
        super.layoutSubviews()
    }

    override func setSelected(selected: Bool, animated: Bool) {
        // Note: this is required, since the cell unhighlight mechanism will reset the new background color
        super.setSelected(selected, animated: animated)
        refreshBackgrounds()
    }

    override func setHighlighted(highlighted: Bool, animated: Bool) {
        // Note: this is required, since the cell unhighlight mechanism will reset the new background color
        super.setHighlighted(highlighted, animated: animated)
        refreshBackgrounds()
    }



    // MARK: - Private Methods
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



    // MARK: - Action Handlers
    @IBAction func undeleteWasPressed(sender: AnyObject) {
        onUndelete?()
    }



    // MARK: - Private Alias
    private typealias Style = WPStyleGuide.Notifications

    // MARK: - Private Settings
    private struct Settings {
        static let separatorInsets = UIEdgeInsets(top: 0.0, left: 12.0, bottom: 0.0, right: 0.0)
        static let subjectNumberOfLinesWithoutSnippet = 3
        static let subjectNumberOfLinesWithSnippet = 2
        static let snippetNumberOfLines = 2
        static let noticonRadius = CGFloat(10)

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
    @IBOutlet private weak var iconImageView: CircularImageView!
    @IBOutlet private weak var noticonLabel: UILabel!
    @IBOutlet private weak var noticonContainerView: UIView!
    @IBOutlet private weak var noticonView: UIView!
    @IBOutlet private weak var subjectLabel: UILabel!
    @IBOutlet private weak var snippetLabel: UILabel!
    @IBOutlet private weak var timestampLabel: UILabel!

    // MARK: - Undo Overlay Optional
    @IBOutlet private var undoOverlayView: NoteUndoOverlayView!
}
