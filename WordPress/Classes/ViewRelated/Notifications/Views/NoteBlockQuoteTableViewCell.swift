import Foundation


@objc public class NoteBlockQuoteTableViewCell : NoteBlockTextTableViewCell
{
    public override var numberOfLines: Int {
        let lines = 4
        return lines
    }
    public override var labelInsets: UIEdgeInsets {
        let insets = UIEdgeInsets(top:0, left:46, bottom:0, right:20)
        return insets
    }
}
