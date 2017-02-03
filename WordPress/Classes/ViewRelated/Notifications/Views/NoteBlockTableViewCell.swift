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

    // MARK: - Public Methods
    func refreshSeparators() {
        // Exception: Badges require no separators
        if isBadge {
            separatorsView.bottomVisible = false
            return
        }

        // Last Rows requires full separators
        separatorsView.bottomInsets = isLastRow ? fullSeparatorInsets : indentedSeparatorInsets
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

    // MARK: - Private Constants
    fileprivate let fullSeparatorInsets = UIEdgeInsets.zero
    fileprivate let indentedSeparatorInsets = UIEdgeInsets(top: 0.0, left: 12.0, bottom: 0.0, right: 0.0)
}
