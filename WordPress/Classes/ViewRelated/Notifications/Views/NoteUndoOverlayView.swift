import Foundation
import WordPressShared


/// This class renders a simple overlay view, with a Legend Label on its right, and an undo button on its
/// right side.
/// The purpose of this helper view is to act as a simple drop-in overlay, to be used by NoteTableViewCell.
/// By doing this, we avoid the need of having yet another UITableViewCell subclass, and thus,
/// we don't need to duplicate any of the mechanisms already available in NoteTableViewCell, such as
/// custom cell separators and Height Calculation.
///
class NoteUndoOverlayView: UIView
{
    // MARK: - Properties

    /// Legend Text
    ///
    var legendText: String? {
        get {
            return legendLabel.text
        }
        set {
            legendLabel.text = newValue
        }
    }

    /// Action Button Text
    ///
    var buttonText: String? {
        get {
            return undoButton.titleForState(.Normal)
        }
        set {
            undoButton.setTitle(newValue, forState: .Normal)
        }
    }


    // MARK: - Overriden Methods
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = Style.noteUndoBackgroundColor

        // Legend
        legendLabel.textColor = Style.noteUndoTextColor
        legendLabel.font = Style.noteUndoTextFont

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
