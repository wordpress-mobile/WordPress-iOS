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
        actionLabel.text = widgetType == .loadingFailed ? LocalizedText.retry : LocalizedText.openApp
        configureLabel.textColor = WidgetStyles.primaryTextColor
        actionLabel.textColor = WidgetStyles.primaryTextColor
        WidgetStyles.configureSeparator(separatorLine)
        separatorVisualEffectView.effect = WidgetStyles.separatorVibrancyEffect
    }

    enum LocalizedText {
        static let configureToday = AppConfiguration.Widget.Localization.configureToday
        static let configureAllTime = AppConfiguration.Widget.Localization.configureAllTime
        static let configureThisWeek = AppConfiguration.Widget.Localization.configureThisWeek
        static let openApp = AppConfiguration.Widget.Localization.openApp
        static let loadingFailed = AppLocalizedString("Couldn't load data", comment: "Message displayed when a Stats widget failed to load data.")
        static let retry = AppLocalizedString("Retry", comment: "Stats widgets label to reload the widget.")
    }

}
