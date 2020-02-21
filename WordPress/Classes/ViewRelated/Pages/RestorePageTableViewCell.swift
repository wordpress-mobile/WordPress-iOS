import Foundation

class RestorePageTableViewCell: BasePageListCell {
    @IBOutlet private var restoreLabel: UILabel!
    @IBOutlet private var restoreButton: UIButton!

    // MARK: - Lifecycle

    override func awakeFromNib() {
        super.awakeFromNib()

        configureView()
        applyStyles()
    }

    // MARK: - Styles

    private func applyStyles() {
        WPStyleGuide.applyRestorePageLabelStyle(restoreLabel)
        WPStyleGuide.applyRestorePageButtonStyle(restoreButton)
    }

    // MARK: - Configuration

    private func configureView() {
        restoreLabel.text = NSLocalizedString("Page moved to trash.", comment: "A short message explaining that a page was moved to the trash bin.")

        let buttonTitle = NSLocalizedString("Undo", comment: "The title of an 'undo' button. Tapping the button moves a trashed page out of the trash folder.")

        restoreButton.setTitle(buttonTitle, for: .normal)
    }
}
