import Foundation
import UIKit
import Gridicons

protocol ReaderPostUndoCellDelegate: NSObjectProtocol {
    func readerCellWillUndo(_ cell: ReaderSavedPostUndoCell)
}

final class ReaderSavedPostUndoCell: UITableViewCell {
    @IBOutlet weak var removed: UILabel!
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var borderedView: UIView!
    @IBOutlet weak var undoButton: UIButton!

    weak var delegate: ReaderPostUndoCellDelegate?

    private enum Strings {
        static let removed = NSLocalizedString("Removed", comment: "Label indicating a post has been removed from Saved For Later")
        static let undo = NSLocalizedString("Undo", comment: "Undo action")
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        setupRemovedLabel()
        setupUndoButton()
        applyStyles()
    }

    @IBAction func undo(_ sender: Any) {
        delegate?.readerCellWillUndo(self)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        setHighlighted(selected, animated: animated)
    }

    private func setupRemovedLabel() {
        removed.text = Strings.removed
    }

    private func setupUndoButton() {
        undoButton.setTitle(Strings.undo, for: .normal)
        let icon = UIImage.gridicon(.undo)
        let tintedIcon = icon.imageWithTintColor(.primary)

        undoButton.setImage(tintedIcon, for: .normal)
    }

    private func applyStyles() {
        backgroundColor = .clear
        contentView.backgroundColor = .listBackground
        borderedView.backgroundColor = .listForeground

        borderedView.layer.borderColor = WPStyleGuide.readerCardCellBorderColor().cgColor
        borderedView.layer.borderWidth = .hairlineBorderWidth

        WPStyleGuide.applyRestoreSavedPostLabelStyle(removed)
        WPStyleGuide.applyRestoreSavedPostTitleLabelStyle(title)
        WPStyleGuide.applyRestoreSavedPostButtonStyle(undoButton)
    }
}
