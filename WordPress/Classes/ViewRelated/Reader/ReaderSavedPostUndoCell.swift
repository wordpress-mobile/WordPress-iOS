import Foundation
import UIKit

protocol ReaderPostUndoCellDelegate: NSObjectProtocol {
    func readerCellWillUndo(_ cell: ReaderSavedPostUndoCell)
}

final class ReaderSavedPostUndoCell: UITableViewCell {
    @IBOutlet weak var removed: UILabel!
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var borderedView: UIView!
    @IBOutlet weak var undoButton: UIButton!

    weak var delegate: ReaderPostUndoCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        applyStyles()
    }

    @IBAction func undo(_ sender: Any) {
        delegate?.readerCellWillUndo(self)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        setHighlighted(selected, animated: animated)
    }

    private func applyStyles() {
        borderedView.layer.borderColor = WPStyleGuide.readerCardCellBorderColor().cgColor
        borderedView.layer.borderWidth = 1.0

        WPStyleGuide.applyRestorePostLabelStyle(removed)
        WPStyleGuide.applyRestorePostLabelStyle(title)
    }
}
