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
        separatorsView.bottomInsets = isLastRow ? fullSeparatorInsets : readableIndentedSeparatorInsets
        separatorsView.bottomVisible = true
    }
    class func reuseIdentifier() -> String {
        return classNameWithoutNamespaces()
    }


    // MARK: - View Methods
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundView = separatorsView
    }

    // MARK: - Private
    fileprivate let fullSeparatorInsets = UIEdgeInsets.zero

    fileprivate var readableIndentedSeparatorInsets: UIEdgeInsets {
        var insets = UIEdgeInsets.zero
        insets.left = readableContentGuide.layoutFrame.origin.x
        return insets
    }
}
