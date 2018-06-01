import Foundation
import UIKit

protocol ReaderPostUndoCellDelegate: NSObjectProtocol {
    func readerCell(_ cell: ReaderSavedPostUndoCell, undoActionForProvider provider: ReaderPostContentProvider)
}

final class ReaderSavedPostUndoCell: UITableViewCell {
    @IBOutlet weak var removed: UILabel!
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var borderedView: UIView!
    @IBOutlet weak var undoButton: UIButton!

    weak var delegate: ReaderPostUndoCellDelegate?
    weak var contentProvider: ReaderPostContentProvider?

    override func awakeFromNib() {
        super.awakeFromNib()
        applyStyles()
    }

    @IBAction func undo(_ sender: Any) {
        guard let provider = contentProvider else {
            return
        }
        delegate?.readerCell(self, undoActionForProvider: provider)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        setHighlighted(selected, animated: animated)
    }

    private func applyStyles() {
        borderedView.layer.borderColor = WPStyleGuide.readerCardCellBorderColor().cgColor
        borderedView.layer.borderWidth = 1.0
//        backgroundColor = WPStyleGuide.greyLighten30()
//        contentView.backgroundColor = WPStyleGuide.greyLighten30()
//        borderedView.layer.borderColor = WPStyleGuide.readerCardCellBorderColor().cgColor
//        borderedView.layer.borderWidth = 1.0

        WPStyleGuide.applyReaderCardTitleLabelStyle(title)
    }
}
