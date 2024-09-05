import UIKit
import WordPressUI

class ReaderTagsFooter: UITableViewHeaderFooterView, NibReusable {

    @IBOutlet weak var actionButton: FancyButton!

    var actionButtonHandler: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.backgroundColor = .systemBackground
        actionButton.isPrimary = false
    }

    // MARK: - IBAction

    @IBAction private func actionButtonTapped(_ sender: UIButton) {
        actionButtonHandler?()
    }
}
