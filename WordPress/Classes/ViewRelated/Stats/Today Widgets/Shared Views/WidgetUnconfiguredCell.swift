import UIKit

enum WidgetType {
    case today
    case allTime
    case thisWeek
    case noConnection

    var configureLabelFont: UIFont {
        switch self {
        case .noConnection:
            return UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .headline).pointSize)
        default:
            return UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .footnote).pointSize)
        }
    }
}

class WidgetUnconfiguredCell: UITableViewCell {

    // MARK: - Properties

    static let reuseIdentifier = "WidgetUnconfiguredCell"

    @IBOutlet private var configureLabel: UILabel!
    @IBOutlet private var separatorLine: UIView!
    @IBOutlet private var separatorVisualEffectView: UIVisualEffectView!
    @IBOutlet private var actionLabel: UILabel!

    private(set) var widgetType: WidgetType?

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

        configureLabel.font = widgetType.configureLabelFont

        configureLabel.text = {
            switch widgetType {
            case .today:
                return LocalizedText.configureToday
            case .allTime:
                return LocalizedText.configureAllTime
            case .thisWeek:
                return LocalizedText.configureThisWeek
            case .noConnection:
                return LocalizedText.noConnection
            }
        }()

        actionLabel.text = widgetType == .noConnection ? LocalizedText.retry : LocalizedText.openWordPress
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
        static let noConnection = NSLocalizedString("No network available", comment: "Displayed in the Stats widgets when there is no network")
        static let retry = NSLocalizedString("Retry", comment: "Stats widgets label to reload the widget")
    }

}
