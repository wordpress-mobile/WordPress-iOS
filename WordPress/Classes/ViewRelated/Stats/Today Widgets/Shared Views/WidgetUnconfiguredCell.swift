import UIKit

enum WidgetType {
    case today
    case allTime
    case thisWeek
}

class WidgetUnconfiguredCell: UITableViewCell {

    // MARK: - Properties

    static let reuseIdentifier = "WidgetUnconfiguredCell"

    @IBOutlet private var configureLabel: UILabel!
    @IBOutlet private var separatorLine: UIView!
    @IBOutlet private var separatorVisualEffectView: UIVisualEffectView!
    @IBOutlet private var actionLabel: UILabel!

    private var widgetType: WidgetType?

    // MARK: - View

    func configure(for widgetType: WidgetType) {
        self.widgetType = widgetType
        configureView()
    }

}

// MARK: - Private Extension

private extension WidgetUnconfiguredCell {

    func configureView() {
        guard let widgetType = widgetType else {
            return
        }

        configureLabel.text = {
            switch widgetType {
            case .today:
                return LocalizedText.configureToday
            case .allTime:
                return LocalizedText.configureAllTime
            case .thisWeek:
                return LocalizedText.configureThisWeek
            }
        }()

        actionLabel.text = LocalizedText.openWordPress
        configureLabel.textColor = WidgetStyles.primaryTextColor
        actionLabel.textColor = WidgetStyles.primaryTextColor
        WidgetStyles.configureSeparator(separatorLine)
        separatorVisualEffectView.effect = WidgetStyles.separatorVibrancyEffect
    }

    enum LocalizedText {
        static let configureToday = NSLocalizedString("Display your site stats for today here. Configure in the WordPress app in your site stats.", comment: "Unconfigured stats today widget helper text")
        static let configureAllTime = NSLocalizedString("Display your all-time site stats here. Configure in the WordPress app in your site stats.", comment: "Unconfigured stats all-time widget helper text")
        static let configureThisWeek = NSLocalizedString("Display your site stats for this week here. Configure in the WordPress app in your site stats.", comment: "Unconfigured stats this week widget helper text")
        static let openWordPress = NSLocalizedString("Open WordPress", comment: "Today widget label to launch WP app")
    }

}
