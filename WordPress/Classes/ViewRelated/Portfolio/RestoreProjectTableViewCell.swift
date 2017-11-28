import UIKit

class RestoreProjectTableViewCell: BasePageListCell {
    @IBOutlet var restoreLabel: UILabel!
    @IBOutlet var restoreButton: UIButton!

    // MARK: - Life Cycle

    override func awakeFromNib() {
        super.awakeFromNib()

        configureView()
        applyStyles()
    }

    // MARK: - Configuration

    func applyStyles() {
        WPStyleGuide.applyRestorePageLabelStyle(restoreLabel)
        WPStyleGuide.applyRestorePageButtonStyle(restoreButton)
    }

    func configureView() {
        restoreLabel.text = NSLocalizedString("Project moved to trash.", comment: "A short message explaining that a project was moved to the trash bin.")
        let buttonTitle = NSLocalizedString("Undo", comment: "The title of an 'undo' button. Tapping the button moves a trashed project out of the trash folder.")
        restoreButton.setTitle(buttonTitle, for: .normal)
    }

}
