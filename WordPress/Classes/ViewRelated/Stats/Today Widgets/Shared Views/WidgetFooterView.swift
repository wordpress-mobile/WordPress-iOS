import UIKit

class WidgetFooterView: UITableViewHeaderFooterView {

    // MARK: - Properties

    static let reuseIdentifier = "WidgetFooterView"

    @IBOutlet private var separatorLine: UIView!
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
        separatorLine.backgroundColor = UIColor(light: .divider, dark: .textSubtle)
        siteUrlLabel.textColor = .textSubtle
        backgroundColorView.backgroundColor = .clear
    }
}
