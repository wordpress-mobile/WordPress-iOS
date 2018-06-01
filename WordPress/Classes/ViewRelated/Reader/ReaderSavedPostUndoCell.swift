import Foundation
import UIKit

protocol ReaderPostUndoCellDelegate: NSObjectProtocol {
    func readerCell(_ cell: ReaderSavedPostUndoCell, undoActionForProvider provider: ReaderPostContentProvider)
}

final class ReaderSavedPostUndoCell: UITableViewCell {
    @IBOutlet weak var removed: UILabel!
    @IBOutlet weak var title: UILabel!

    weak var delegate: ReaderPostUndoCellDelegate?
    weak var contentProvider: ReaderPostContentProvider?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
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
}
