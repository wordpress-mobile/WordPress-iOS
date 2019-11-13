import UIKit

class WidgetUnconfiguredCell: UITableViewCell {

    // MARK: - Properties

    static let reuseIdentifier = "WidgetUnconfiguredCell"

    @IBOutlet private weak var configureLabel: UILabel!
    @IBOutlet private weak var separatorLine: UIView!
    @IBOutlet private weak var openWordPressLabel: UILabel!

    // MARK: - View

    override func awakeFromNib() {
        super.awakeFromNib()
        configureView()
    }

}

// MARK: - Private Extension

private extension WidgetUnconfiguredCell {

    func configureView() {
        configureLabel.text = LocalizedText.configure
        openWordPressLabel.text = LocalizedText.openWordPress

        configureLabel.textColor = .text
        openWordPressLabel.textColor = .text
        separatorLine.backgroundColor = UIColor(light: .divider, dark: .textSubtle)
    }

    enum LocalizedText {
        static let configure = NSLocalizedString("Display your site stats for today here. Configure in the WordPress app in your site stats.", comment: "Unconfigured stats today widget helper text")
        static let openWordPress = NSLocalizedString("Open WordPress", comment: "Today widget label to launch WP app")
    }

}
