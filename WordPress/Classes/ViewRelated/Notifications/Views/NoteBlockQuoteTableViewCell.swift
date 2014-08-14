import Foundation


@objc public class NoteBlockQuoteTableViewCell : NoteBlockTextTableViewCell
{
    private let MaxLines:   Int             = 4
    private let Insets:     UIEdgeInsets    = UIEdgeInsets(top:0.0, left:46.0, bottom:0.0, right:20.0)
    
    public override func numberOfLines() -> Int {
        return MaxLines
    }
 
    public override func labelPreferredMaxLayoutWidth() -> CGFloat {
        return CGRectGetWidth(self.bounds) - Insets.left - Insets.right
    }
}
