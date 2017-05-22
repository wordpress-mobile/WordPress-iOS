import Foundation
import WordPressShared
import MGSwipeTableCell

/// The purpose of this class is to render a Notification entity, onscreen.
/// This cell should be loaded from its nib, since the autolayout constraints and outlets are not generated
/// via code.
/// Supports specific styles for Unapproved Comment Notifications, Unread Notifications, and a brand
/// new "Undo Deletion" mechanism has been implemented. See "NoteUndoOverlayView" for reference.
///
class NoteTableViewCell: MGSwipeTableCell {
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
    var showsUndeleteOverlay: Bool {
        get {
            return undeleteOverlayText != nil
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
    var undeleteOverlayText: String? {
        didSet {
            if undeleteOverlayText != oldValue {
                refreshSubviewVisibility()
                refreshBackgrounds()
                refreshUndoOverlay()
                refreshSelectionStyle()
            }
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
            updateTextBackgroundColor(newBackgroundColor: backgroundColor)
        }
    }
    var onUndelete: (() -> Void)?



    // MARK: - Public Methods
    class func reuseIdentifier() -> String {
        return classNameWithoutNamespaces()
    }

    func downloadIconWithURL(_ url: URL?) {
        let isGravatarURL = url.map { Gravatar.isGravatarURL($0) } ?? false
        if isGravatarURL {
            downloadGravatarWithURL(url)
            return
        }

        // Handle non-gravatar images
        let placeholderImage = Style.blockGravatarPlaceholderImage(isApproved: !unapproved)
        iconImageView.downloadImage(url, placeholderImage: placeholderImage, success: nil, failure: {[weak self] (error) in
            // Note: Don't cache 404's. Otherwise Unapproved / Approved gravatars won't switch!
            if (self?.gravatarURL == url) == true {
                self?.gravatarURL = nil
            }
        })

        gravatarURL = url
    }


    // MARK: - Gravatar Helpers
    fileprivate func downloadGravatarWithURL(_ url: URL?) {
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
            failure: {[weak self] (error: Error?) in
                // Note: Don't cache 404's. Otherwise Unapproved / Approved gravatars won't switch!
                if (self?.gravatarURL == url) == true {
                    self?.gravatarURL = nil
                }
        })

        gravatarURL = url
    }



    // MARK: - UITableViewCell Methods
    override func awakeFromNib() {
        super.awakeFromNib()

        iconImageView.image = WPStyleGuide.Notifications.gravatarPlaceholderImage

        noticonContainerView.layer.cornerRadius = Settings.noticonContainerRadius

        noticonView.layer.cornerRadius = Settings.noticonRadius
        noticonLabel.font = Style.noticonFont
        noticonLabel.textColor = Style.noticonTextColor

        subjectLabel.numberOfLines = Settings.subjectNumberOfLinesWithSnippet
        subjectLabel.shadowOffset = CGSize.zero

        snippetLabel.numberOfLines = Settings.snippetNumberOfLines

        // Separators: Setup bottom separators!
        separatorsView.bottomColor = WPStyleGuide.Notifications.noteSeparatorColor
        backgroundView = separatorsView
    }

    override func layoutSubviews() {
        refreshBackgrounds()
        super.layoutSubviews()
        refreshSeparators()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        // Note: this is required, since the cell unhighlight mechanism will reset the new background color
        super.setSelected(selected, animated: animated)
        refreshBackgrounds()
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        // Note: this is required, since the cell unhighlight mechanism will reset the new background color
        super.setHighlighted(highlighted, animated: animated)
        refreshBackgrounds()
    }


    // MARK: - Private Methods

    func refreshSeparators() {
        var insets = UIEdgeInsets.zero
        insets.left = readableContentGuide.layoutFrame.origin.x
        separatorsView.bottomInsets = insets
    }

    fileprivate func refreshBackgrounds() {
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
        guard newBackgroundColor != backgroundColor else {
            return
        }

        // Failsafe:
        // Under unknown scenarios, `backgroundColor.didSet` is suspected of not being called. We'll make an explicit
        // call, in order to set the Text Background Colors.
        //
        super.backgroundColor = newBackgroundColor
        updateTextBackgroundColor(newBackgroundColor: newBackgroundColor)
    }

    fileprivate func refreshSelectionStyle() {
        selectionStyle = showsUndeleteOverlay ? .none : .gray
    }

    fileprivate func refreshSubviewVisibility() {
        for subview in contentView.subviews {
            subview.isHidden = showsUndeleteOverlay
        }
    }

    fileprivate func refreshNumberOfLines() {
        // When the snippet is present, let's clip the number of lines in the subject
        let showsSnippet = attributedSnippet != nil
        subjectLabel.numberOfLines =  Settings.subjectNumberOfLines(showsSnippet)
    }

    fileprivate func refreshUndoOverlay() {
        // Remove
        guard showsUndeleteOverlay else {
            undoOverlayView?.removeFromSuperview()
            undoOverlayView = nil
            return
        }

        // Lazy Load
        if undoOverlayView == nil {
            let nibName = NoteUndoOverlayView.classNameWithoutNamespaces()
            Bundle.main.loadNibNamed(nibName, owner: self, options: nil)
            undoOverlayView.translatesAutoresizingMaskIntoConstraints = false

            contentView.addSubview(undoOverlayView)
            contentView.pinSubviewToAllEdges(undoOverlayView)
        }

        undoOverlayView.isHidden = false
        undoOverlayView.legendText = undeleteOverlayText
    }


    // MARK: - Helpers

    private func updateTextBackgroundColor(newBackgroundColor: UIColor?) {
        snippetLabel.backgroundColor = backgroundColor
        subjectLabel.backgroundColor = backgroundColor
        separatorsView.backgroundColor = backgroundColor
    }


    // MARK: - Action Handlers
    @IBAction func undeleteWasPressed(_ sender: AnyObject) {
        onUndelete?()
    }


    // MARK: - Private Alias
    fileprivate typealias Style = WPStyleGuide.Notifications

    // MARK: - Private Settings
    fileprivate struct Settings {
        static let subjectNumberOfLinesWithoutSnippet = 3
        static let subjectNumberOfLinesWithSnippet = 2
        static let snippetNumberOfLines = 2
        static let noticonRadius = CGFloat(10)
        static let noticonContainerRadius = CGFloat(12)

        static func subjectNumberOfLines(_ showsSnippet: Bool) -> Int {
            return showsSnippet ? subjectNumberOfLinesWithSnippet : subjectNumberOfLinesWithoutSnippet
        }
    }

    // MARK: - Private Properties
    fileprivate var gravatarURL: URL?
    fileprivate var separatorsView = SeparatorsView()

    // MARK: - IBOutlets
    @IBOutlet var iconImageView: CircularImageView!
    @IBOutlet var noticonLabel: UILabel!
    @IBOutlet var noticonContainerView: UIView!
    @IBOutlet var noticonView: UIView!
    @IBOutlet var subjectLabel: UILabel!
    @IBOutlet var snippetLabel: UILabel!

    // MARK: - Undo Overlay Optional
    @IBOutlet var undoOverlayView: NoteUndoOverlayView!
}
