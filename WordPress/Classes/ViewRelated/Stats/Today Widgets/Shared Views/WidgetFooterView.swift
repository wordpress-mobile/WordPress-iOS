import UIKit

class WidgetFooterView: UITableViewHeaderFooterView {

    // MARK: - Properties

    static let reuseIdentifier = "WidgetFooterView"

    @IBOutlet private weak var separatorLine: UIView!
    @IBOutlet private weak var siteUrlLabel: UILabel!
    @IBOutlet private weak var backgroundColorView: UIView!

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
        separatorLine.backgroundColor = UIColor(light: .divider, dark: .textSubtle)
        siteUrlLabel.textColor = .textSubtle
        backgroundColorView.backgroundColor = .clear
    }
}
