import Foundation
import WordPressShared

class NoteBlockTableViewCell: WPTableViewCell {
    // MARK: - Public Properties
    var isBadge: Bool = false {
        didSet {
            refreshSeparators()
        }
    }
    var isLastRow: Bool = false {
        didSet {
            refreshSeparators()
        }
    }
    var readableSeparatorInsets: UIEdgeInsets {
        var insets = UIEdgeInsets.zero
        let readableLayoutFrame = readableContentGuide.layoutFrame
        insets.left = readableLayoutFrame.origin.x
        insets.right = frame.size.width - (readableLayoutFrame.origin.x + readableLayoutFrame.size.width)
        return insets
    }
    var separatorsView = SeparatorsView()

    override func layoutSubviews() {
        super.layoutSubviews()
        refreshSeparators()
    }

    // MARK: - Public Methods
    func refreshSeparators() {
        // Exception: Badges require no separators
        if isBadge {
            separatorsView.bottomVisible = false
            return
        }

        // Last Rows requires full separators
        separatorsView.bottomInsets = isLastRow ? fullSeparatorInsets : readableSeparatorInsets
        separatorsView.bottomVisible = true
    }
    class func reuseIdentifier() -> String {
        return classNameWithoutNamespaces()
    }

    /// Performs the action when an internet connection is available
    /// If no internet connection is available an error message is displayed
    ///
    func onAvailableInternetConnectionDo(action: () -> Void) {
        let appDelegate = WordPressAppDelegate.sharedInstance()
        guard appDelegate!.connectionAvailable else {
            let title = NSLocalizedString("Error", comment: "Title of error prompt.")
            let message = NSLocalizedString("The Internet connection appears to be offline",
                                            comment: "Message of error prompt shown when a user tries to perform an action without an internet connection.")
            WPError.showAlert(withTitle: title, message: message)
            return
        }
        action()
    }

    // MARK: - View Methods
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundView = separatorsView
    }

    // MARK: - Private
    fileprivate let fullSeparatorInsets = UIEdgeInsets.zero
}
