import Foundation
import WordPressShared

/**
*  @class       NoteUndoOverlayView
*  @brief       This class renders a simple overlay view, with a Legend Label on its right, and an undo button on its
*               right side.
*  @details     The purpose of this helper view is to act as a simple drop-in overlay, to be used by NoteTableViewCell.
*               By doing this, we avoid the need of having yet another UITableViewCell subclass, and thus,
*               we don't need to duplicate any of the mechanisms already available in NoteTableViewCell, such as
*               custom cell separators and Height Calculation.
*/

@objc public class NoteUndoOverlayView : UIView
{
    // MARK: - NSCoder
    public override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor         = Style.noteUndoBackgroundColor
        
        // Legend
        legendLabel.text        = NSLocalizedString("Comment has been deleted", comment: "Displayed when a Comment is removed")
        legendLabel.textColor   = Style.noteUndoTextColor
        legendLabel.font        = Style.noteUndoTextFont
        
        // Button
        undoButton.titleLabel?.font = Style.noteUndoTextFont
        undoButton.setTitle(NSLocalizedString("Undo", comment: "Revert an operation"), forState: .Normal)
        undoButton.setTitleColor(Style.noteUndoTextColor, forState: .Normal)
    }
    
    
    
    // MARK: - Private Alias
    private typealias Style = WPStyleGuide.Notifications
    
    // MARK: - Private Outlets
    @IBOutlet private weak var legendLabel: UILabel!
    @IBOutlet private weak var undoButton:  UIButton!
}
