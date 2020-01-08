import UIKit
import NotificationCenter

class WidgetFooterView: UITableViewHeaderFooterView {

    // MARK: - Properties

    static let reuseIdentifier = "WidgetFooterView"

    @IBOutlet private var separatorLine: UIView!
    @IBOutlet private var separatorVisualEffect: UIVisualEffectView!
    @IBOutlet private var siteUrlLabel: UILabel!
    @IBOutlet private var backgroundColorView: UIView!

    // MARK: - View

    override func awakeFromNib() {
        super.awakeFromNib()
        configureColors()
    }

    func configure(siteUrl: String) {
        siteUrlLabel.text = siteUrl
    }

}

// MARK: - Private Extension

private extension WidgetFooterView {
    func configureColors() {
        siteUrlLabel.textColor = .textSubtle
        backgroundColorView.backgroundColor = .clear

        if #available(iOS 13, *) {
            separatorLine.backgroundColor = UIColor(white: 1.0, alpha: 0.5)
            separatorLine.tintColor = UIColor(white: 1.0, alpha: 0.5)
            separatorVisualEffect.effect = UIVibrancyEffect.widgetEffect(forVibrancyStyle: .separator)
        } else {
            separatorLine.backgroundColor = .divider
            separatorLine.tintColor = .divider
            separatorVisualEffect.effect = UIVibrancyEffect.widgetSecondary()
        }
    }
}
