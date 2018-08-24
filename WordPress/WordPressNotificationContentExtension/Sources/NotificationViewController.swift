import UIKit
import UserNotifications
import UserNotificationsUI

// MARK: - NotificationViewController

/// Responsible for enhancing the visual appearance of designated push notifications.
@objc(NotificationViewController)
class NotificationViewController: UIViewController {

    // MARK: Properties

    /// Long Look content is inset from iOS container bounds
    private struct Metrics {
        static let verticalInset = CGFloat(20)
    }

    /// This view model contains the attributes necessary to render a rich notification
    private var viewModel: RichNotificationViewModel? {
        didSet {
            setupContentView()
        }
    }

    /// The subview responsible for rendering a notification's Long Look
    private var contentView: NotificationContentView?

    // MARK: UIViewController

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        view.subviews.forEach { $0.removeFromSuperview() }
        viewModel = nil
        contentView = nil
    }

    // MARK: Private behavior

    /// Responsible for instantiation, installation & configuration of the content view
    private func setupContentView() {
        guard let viewModel = viewModel else { return }

        view.translatesAutoresizingMaskIntoConstraints = false

        let contentView = NotificationContentView(viewModel: viewModel)
        self.contentView = contentView
        view.addSubview(contentView)

        let readableGuide = view.readableContentGuide
        let constraints = [
            contentView.topAnchor.constraint(equalTo: readableGuide.topAnchor, constant: Metrics.verticalInset),
            contentView.bottomAnchor.constraint(equalTo: readableGuide.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: readableGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: readableGuide.trailingAnchor)
        ]
        NSLayoutConstraint.activate(constraints)
    }
}

// MARK: - UNNotificationContentExtension

extension NotificationViewController: UNNotificationContentExtension {
    func didReceive(_ notification: UNNotification) {
        let notificationContent = notification.request.content
        viewModel = RichNotificationViewModel(notificationContent: notificationContent)
    }
}
