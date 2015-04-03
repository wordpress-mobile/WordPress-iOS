import Foundation


@objc public class NoteBlockTableViewCell : WPTableViewCell
{
    public override func awakeFromNib() {
        super.awakeFromNib()
        backgroundView = separatorsView
    }
    
    public var separatorsView = NoteSeparatorsView()
}
