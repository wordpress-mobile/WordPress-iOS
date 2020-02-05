import UIKit

class WidgetUrlCell: UITableViewCell {

    // MARK: - Properties

    static let reuseIdentifier = "WidgetUrlCell"
    static let height: CGFloat = 32

    @IBOutlet private var separatorLine: UIView!
    @IBOutlet private var separatorVisualEffectView: UIVisualEffectView!
    @IBOutlet private var siteUrlLabel: UILabel!

    // MARK: - View

    override func awakeFromNib() {
        super.awakeFromNib()
        configureColors()
    }

    func configure(siteUrl: String, hideSeparator: Bool = false) {
        siteUrlLabel.text = siteUrl
        separatorVisualEffectView.isHidden = hideSeparator
    }

}

// MARK: - Private Extension

private extension WidgetUrlCell {
    func configureColors() {
        siteUrlLabel.textColor = WidgetStyles.secondaryTextColor
        WidgetStyles.configureSeparator(separatorLine)
        separatorVisualEffectView.effect = WidgetStyles.separatorVibrancyEffect
    }
}
