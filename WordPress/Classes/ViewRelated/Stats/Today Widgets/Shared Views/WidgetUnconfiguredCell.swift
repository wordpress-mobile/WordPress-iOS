import UIKit

enum WidgetType {
    case today
    case allTime
}

class WidgetUnconfiguredCell: UITableViewCell {

    // MARK: - Properties

    static let reuseIdentifier = "WidgetUnconfiguredCell"

    @IBOutlet private var configureLabel: UILabel!
    @IBOutlet private var separatorLine: UIView!
    @IBOutlet private var separatorVisualEffectView: UIVisualEffectView!
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
        configureLabel.textColor = WidgetStyles.primaryTextColor
        openWordPressLabel.textColor = WidgetStyles.primaryTextColor
        WidgetStyles.configureSeparator(separatorLine)
        WidgetStyles.configureSeparatorVisualEffectView(separatorVisualEffectView)
    }

    enum LocalizedText {
        static let configureToday = NSLocalizedString("Display your site stats for today here. Configure in the WordPress app in your site stats.", comment: "Unconfigured stats today widget helper text")
        static let configureAllTime = NSLocalizedString("Display your all-time site stats here. Configure in the WordPress app in your site stats.", comment: "Unconfigured stats all-time widget helper text")
        static let openWordPress = NSLocalizedString("Open WordPress", comment: "Today widget label to launch WP app")
    }

}
