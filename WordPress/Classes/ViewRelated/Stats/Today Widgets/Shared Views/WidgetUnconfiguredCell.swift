import UIKit

enum WidgetType {
    case today
    case allTime
    case thisWeek
    case loadingFailed

    var configureLabelFont: UIFont {
        switch self {
        case .loadingFailed:
            return WidgetStyles.headlineFont
        default:
            return WidgetStyles.footnoteNote
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
            case .loadingFailed:
                return LocalizedText.loadingFailed
            }
        }()

        configureLabel.font = widgetType.configureLabelFont
        actionLabel.text = widgetType == .loadingFailed ? LocalizedText.retry : LocalizedText.openWordPress
        configureLabel.textColor = WidgetStyles.primaryTextColor
        actionLabel.textColor = WidgetStyles.primaryTextColor
        WidgetStyles.configureSeparator(separatorLine)
        separatorVisualEffectView.effect = WidgetStyles.separatorVibrancyEffect
    }

    enum LocalizedText {
        static let configureToday = AppLocalizedString("Display your site stats for today here. Configure in the WordPress app in your site stats.", comment: "Unconfigured stats today widget helper text")
        static let configureAllTime = AppLocalizedString("Display your all-time site stats here. Configure in the WordPress app in your site stats.", comment: "Unconfigured stats all-time widget helper text")
        static let configureThisWeek = AppLocalizedString("Display your site stats for this week here. Configure in the WordPress app in your site stats.", comment: "Unconfigured stats this week widget helper text")
        static let openWordPress = AppLocalizedString("Open WordPress", comment: "Today widget label to launch WP app")
        static let loadingFailed = AppLocalizedString("Couldn't load data", comment: "Message displayed when a Stats widget failed to load data.")
        static let retry = AppLocalizedString("Retry", comment: "Stats widgets label to reload the widget.")
    }

}
