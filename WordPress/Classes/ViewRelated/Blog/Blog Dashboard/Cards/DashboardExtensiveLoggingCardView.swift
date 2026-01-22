import UIKit
import DesignSystem
import Support

class DashboardExtensiveLoggingCardView: UIView {

    var onTurnOffTapped: (() -> Void)?
    weak var presenterViewController: UIViewController?

    private lazy var cardFrameView: BlogDashboardCardFrameView = {
        let frameView = BlogDashboardCardFrameView()
        frameView.translatesAutoresizingMaskIntoConstraints = false
        frameView.setTitle(Strings.cardTitle)
        return frameView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    private func setupViews() {
        addSubview(cardFrameView)
        pinSubviewToAllEdges(cardFrameView)

        cardFrameView.onViewTap = { [weak self] in
            self?.showAlert()
        }
    }

    private func showAlert() {
        let alert = UIAlertController(
            title: Strings.alertTitle,
            message: Strings.alertMessage,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: Strings.dismissButton, style: .cancel))
        alert.addAction(UIAlertAction(title: Strings.turnOffButton, style: .default) { [weak self] _ in
            self?.turnOffExtensiveLogging()
        })
        presenterViewController?.present(alert, animated: true)
    }

    private func turnOffExtensiveLogging() {
        ExtensiveLogging.enabled = false
        Notice(title: Strings.noticeTitle, feedbackType: .success).post()

        onTurnOffTapped?()
    }
}

private enum Strings {
    static let cardTitle = NSLocalizedString(
        "dashboard.extensiveLogging.title",
        value: "Extensive logging is turned on",
        comment: "Title for the extensive logging card on dashboard"
    )

    static let alertTitle = NSLocalizedString(
        "dashboard.extensiveLogging.alert.title",
        value: "Extensive Logging",
        comment: "Alert title for extensive logging"
    )

    static let alertMessage = NSLocalizedString(
        "dashboard.extensiveLogging.alert.message",
        value: "Extensive logging is currently enabled. This helps with troubleshooting but may impact performance. Turn it off if you don't need it.",
        comment: "Alert message explaining that extensive logging is enabled and should be turned off if not needed"
    )

    static let dismissButton = NSLocalizedString(
        "dashboard.extensiveLogging.alert.dismiss",
        value: "Dismiss",
        comment: "Button to dismiss the extensive logging alert"
    )

    static let turnOffButton = NSLocalizedString(
        "dashboard.extensiveLogging.alert.turnOff",
        value: "Turn Off",
        comment: "Button to turn off extensive logging"
    )

    static let noticeTitle = NSLocalizedString(
        "dashboard.extensiveLogging.disabled",
        value: "Extensive logging disabled",
        comment: "Notice shown when extensive logging is successfully disabled"
    )
}
