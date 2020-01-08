import UIKit
import NotificationCenter

enum WidgetType {
    case today
    case allTime
}

class WidgetUnconfiguredCell: UITableViewCell {

    // MARK: - Properties

    static let reuseIdentifier = "WidgetUnconfiguredCell"

    @IBOutlet private var configureLabel: UILabel!
    @IBOutlet private var separatorLine: UIView!
    @IBOutlet private var separatorVisualEffect: UIVisualEffectView!
    @IBOutlet private var openWordPressLabel: UILabel!

    // MARK: - View

    func configure(for widgetType: WidgetType) {
        configureView(for: widgetType)
    }

}

// MARK: - Private Extension

private extension WidgetUnconfiguredCell {

    func configureView(for widgetType: WidgetType) {

        configureLabel.text = {
            switch widgetType {
            case .today:
                return LocalizedText.configureToday
            case .allTime:
                return LocalizedText.configureAllTime
            }
        }()

        openWordPressLabel.text = LocalizedText.openWordPress
        configureLabel.textColor = .text
        openWordPressLabel.textColor = .text

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

    enum LocalizedText {
        static let configureToday = NSLocalizedString("Display your site stats for today here. Configure in the WordPress app in your site stats.", comment: "Unconfigured stats today widget helper text")
        static let configureAllTime = NSLocalizedString("Display your all-time site stats here. Configure in the WordPress app in your site stats.", comment: "Unconfigured stats all-time widget helper text")
        static let openWordPress = NSLocalizedString("Open WordPress", comment: "Today widget label to launch WP app")
    }

}
