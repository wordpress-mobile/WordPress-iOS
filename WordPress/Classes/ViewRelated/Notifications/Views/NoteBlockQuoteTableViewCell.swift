import Foundation


@objc public class NoteBlockQuoteTableViewCell : NoteBlockTextTableViewCell
{
    public override var numberOfLines: Int {
        return lines
    }

    public override var labelInsets: UIEdgeInsets {
        return insets
    }
    
    private let lines   = 0
    private let insets  = UIEdgeInsets(top:0, left:46, bottom:0, right:20)
}
