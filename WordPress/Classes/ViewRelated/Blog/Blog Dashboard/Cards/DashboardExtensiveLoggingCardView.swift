import UIKit
import DesignSystem
import Support
import SwiftUI
import WordPressUI

class DashboardExtensiveLoggingCardView: UIView {
    var onTurnOffTapped: (() -> Void)?
    weak var presenterViewController: UIViewController?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    private func setupViews() {
        // Same as `BlogDashboardCardFrameView`
        self.backgroundColor = .secondarySystemGroupedBackground
        self.layer.masksToBounds = true
        self.layer.cornerRadius = DesignConstants.radius(.large)

        let content = UIHostingView(view: CardContent())
        content.translatesAutoresizingMaskIntoConstraints = false
        addSubview(content)
        pinSubviewToAllEdges(content)

        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showAlert)))
    }

    @objc private func showAlert() {
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

private struct CardContent: View {
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(.orange)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading) {
                Text(Strings.cardTitle)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(Strings.cardSubtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "info.circle.fill")
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}

private enum Strings {
    static let cardTitle = NSLocalizedString(
        "dashboard.extensiveLogging.title",
        value: "Extensive Logging Enabled",
        comment: "Title for the extensive logging card on dashboard"
    )
    static let cardSubtitle = NSLocalizedString(
        "dashboard.extensiveLogging.subtitle",
        value: "This feature may impact performance",
        comment: "Subtitle for the extensive logging card on dashboard"
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
