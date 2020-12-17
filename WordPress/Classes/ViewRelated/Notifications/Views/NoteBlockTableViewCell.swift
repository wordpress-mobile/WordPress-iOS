import Foundation
import WordPressShared

class NoteBlockTableViewCell: WPTableViewCell {

    /// Represents the (full, side to side) Separator Insets
    ///
    private let fullSeparatorInsets = UIEdgeInsets.zero

    /// Indicates if the receiver represents a Badge Block
    ///
    /// - Note: After setting this property you should explicitly call `refreshSeparators` from within `UITableView.willDisplayCell`.
    ///
    @objc var isBadge = false {
        didSet {
            separatorsView.backgroundColor = WPStyleGuide.Notifications.blockBackgroundColorForRichText(isBadge)
        }
    }

    /// Indicates if the receiver is the last row in the group.
    ///
    /// - Note: After setting this property you should explicitly call `refreshSeparators` from within `UITableView.willDisplayCell`.
    ///
    @objc var isLastRow = false

    /// Readability Insets
    ///
    @objc var readableSeparatorInsets: UIEdgeInsets {
        var insets = UIEdgeInsets.zero
        let readableLayoutFrame = readableContentGuide.layoutFrame
        insets.left = readableLayoutFrame.origin.x
        insets.right = frame.size.width - (readableLayoutFrame.origin.x + readableLayoutFrame.size.width)
        return insets
    }

    /// Separators View
    ///
    @objc var separatorsView: SeparatorsView = {
        let view = SeparatorsView()
        view.backgroundColor = .listForeground
        return view
    }()


    // MARK: - Overridden Methods

    override func layoutSubviews() {
        super.layoutSubviews()
        refreshSeparators()
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundView = separatorsView
        backgroundColor = .listForeground
    }


    // MARK: - Public API

    /// Updates the Separators Insets / Visibility. This API should be called from within `UITableView.willDisplayCell`.
    ///
    /// -   Note:
    ///     `readableSeparatorInsets`, if executed from within `cellForRowAtIndexPath`, will produce an "invalid" layout cycle (since there won't
    ///     be a superview). Such "Invalid" layout cycle appears to be yielding an invalid `intrinsicContentSize` calculation, which is then cached,
    ///     and we end up with strings cutoff onScreen. =(
    ///
    @objc func refreshSeparators() {
        // Exception: Badges require no separators
        if isBadge {
            separatorsView.bottomVisible = false
            return
        }

        // Last Rows requires full separators
        separatorsView.bottomInsets = isLastRow ? fullSeparatorInsets : readableSeparatorInsets
        separatorsView.bottomVisible = true
    }

    @objc class func reuseIdentifier() -> String {
        return classNameWithoutNamespaces()
    }
}
