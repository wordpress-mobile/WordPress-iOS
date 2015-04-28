import Foundation


@objc public class NoteBlockTableViewCell : WPTableViewCell
{
    // MARK: - Public Properties
    public var isBadge: Bool            = false {
        didSet {
            refreshSeparators()
        }
    }
    public var isLastRow: Bool          = false {
        didSet {
            refreshSeparators()
        }
    }
    public var separatorsView           = NoteSeparatorsView()
    
    // MARK: - Public Methods
    public func refreshSeparators() {
        // Exception: Badges require no separators
        if isBadge {
            separatorsView.bottomVisible = false
            return;
        }
        
        // Last Rows requires full separators
        separatorsView.bottomInsets     = isLastRow ? fullSeparatorInsets : indentedSeparatorInsets
        separatorsView.bottomVisible    = true
        
    }
    
    // MARK: - View Methods
    public override func awakeFromNib() {
        super.awakeFromNib()
        backgroundView = separatorsView
    }
    
    // MARK: - Private Constants
    private let fullSeparatorInsets     = UIEdgeInsetsZero
    private let indentedSeparatorInsets = UIEdgeInsetsMake(0.0, 12.0, 0.0, 0.0)
}
