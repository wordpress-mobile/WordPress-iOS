import UIKit

class ReaderTagsFooter: UITableViewHeaderFooterView, NibReusable {

    @IBOutlet weak var actionButton: FancyButton!

    var actionButtonHandler: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.backgroundColor = .basicBackground
        actionButton.isPrimary = false
    }

    // MARK: - IBAction

    @IBAction private func actionButtonTapped(_ sender: UIButton) {
        actionButtonHandler?()
    }
}
