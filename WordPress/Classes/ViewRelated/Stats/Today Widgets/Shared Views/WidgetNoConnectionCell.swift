import UIKit

class WidgetNoConnectionCell: UITableViewCell {

    // MARK: - Properties

    static let reuseIdentifier = "WidgetNoConnectionCell"

    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var messageLabel: UILabel!

    // MARK: - View

    override func awakeFromNib() {
        super.awakeFromNib()
        configureView()
    }

}

private extension WidgetNoConnectionCell {

    func configureView() {
        titleLabel.text = LocalizedText.title
        messageLabel.text = LocalizedText.message
        titleLabel.textColor = WidgetStyles.primaryTextColor
        messageLabel.textColor = WidgetStyles.primaryTextColor
    }

    enum LocalizedText {
        static let title = AppLocalizedString("No network available", comment: "Displayed in the Stats widgets when there is no network")
        static let message = AppLocalizedString("Stats will be updated next time you're online", comment: "Displayed in the Stats widgets when there is no network")
    }

}
