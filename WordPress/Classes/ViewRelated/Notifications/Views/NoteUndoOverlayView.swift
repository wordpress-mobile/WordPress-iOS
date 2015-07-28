import Foundation


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
