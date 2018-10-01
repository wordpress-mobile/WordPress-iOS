import Foundation
import WordPressShared


/// This class renders a simple overlay view, with a Legend Label on its right, and an undo button on its
/// right side.
/// The purpose of this helper view is to act as a simple drop-in overlay, to be used by NoteTableViewCell.
/// By doing this, we avoid the need of having yet another UITableViewCell subclass, and thus,
/// we don't need to duplicate any of the mechanisms already available in NoteTableViewCell, such as
/// custom cell separators and Height Calculation.
///
class NoteUndoOverlayView: UIView {
    // MARK: - Properties

    /// Legend Text
    ///
    @objc var legendText: String? {
        get {
            return legendLabel.text
        }
        set {
            legendLabel.text = newValue
        }
    }

    /// Action Button Text
    ///
    @objc var buttonText: String? {
        get {
            return undoButton.title(for: UIControl.State())
        }
        set {
            undoButton.setTitle(newValue, for: UIControl.State())
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
        undoButton.setTitle(NSLocalizedString("Undo", comment: "Revert an operation"), for: UIControl.State())
        undoButton.setTitleColor(Style.noteUndoTextColor, for: UIControl.State())
    }


    // MARK: - Private Alias
    fileprivate typealias Style = WPStyleGuide.Notifications

    // MARK: - Private Outlets
    @IBOutlet fileprivate weak var legendLabel: UILabel!
    @IBOutlet fileprivate weak var undoButton: UIButton!
}
