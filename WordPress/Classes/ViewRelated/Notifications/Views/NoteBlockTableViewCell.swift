import Foundation
import WordPressShared

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
    public var separatorsView           = SeparatorsView()
    
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

    public func isLayoutCell() -> Bool {
        return self.dynamicType.layoutIdentifier() == reuseIdentifier
    }
    
    public class func reuseIdentifier() -> String {
        return classNameWithoutNamespaces()
    }
    
    public class func layoutIdentifier() -> String {
        return classNameWithoutNamespaces() + "-Layout"
    }
    
    
    // MARK: - View Methods
    public override func awakeFromNib() {
        super.awakeFromNib()
        backgroundView = separatorsView
    }
    
    // MARK: - Private Constants
    private let fullSeparatorInsets     = UIEdgeInsetsZero
    private let indentedSeparatorInsets = UIEdgeInsets(top: 0.0, left: 12.0, bottom: 0.0, right: 0.0)
}
