import UIKit
import UserNotifications
import UserNotificationsUI

import WordPressKit

// MARK: - NotificationViewController

/// Responsible for enhancing the visual appearance of designated push notifications.
class NotificationViewController: UIViewController {

    // MARK: Properties

    /// Long Look content is inset from iOS container bounds
    private struct Metrics {
        static let verticalInset = CGFloat(20)
    }

    /// Manages analytics calls via Tracks
    private let tracks = Tracks(appGroupName: WPAppGroupName)

    /// The service used to retrieve remote notifications
    private var notificationService: NotificationSyncServiceRemote?

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

        notificationService?.wordPressComRestApi.invalidateAndCancelTasks()
        notificationService = nil

        view.subviews.forEach { $0.removeFromSuperview() }
        viewModel = nil
        contentView = nil
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        DispatchQueue.main.async {
            self.contentView?.reloadContent()
        }
    }

    // MARK: Private behavior

    /// Responsible for instantiation, installation & configuration of the content view
    private func setupContentView() {
        guard let viewModel = viewModel else {
            return
        }

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

        guard let data = notificationContent.userInfo[CodingUserInfoKey.richNotificationViewModel.rawValue] as? Data else {
            return
        }
        viewModel = RichNotificationViewModel(data: data)

        let username = readExtensionUsername()
        tracks.wpcomUsername = username

        let token = readExtensionToken()
        tracks.trackExtensionLaunched(token != nil)

        markNotificationAsReadIfNeeded()
    }
}

// MARK: - Private behavior

private extension NotificationViewController {
    /// Attempts to mark the notification as read via the remote service. This promotes UX consistency between the
    /// Notification received and how it is rendered on the Notifications tab within the app.
    ///
    func markNotificationAsReadIfNeeded() {
        guard let token = readExtensionToken(),
            let viewModel = viewModel,
            let notificationIdentifier = viewModel.notificationIdentifier,
            let notificationHasBeenRead = viewModel.notificationReadStatus,
            notificationHasBeenRead == false else {

            return
        }

        let api = WordPressComRestApi(oAuthToken: token)
        notificationService = NotificationSyncServiceRemote(wordPressComRestApi: api)

        notificationService?.updateReadStatus(notificationIdentifier, read: true) { [tracks] error in
            guard let error = error else {
                return
            }
            tracks.trackFailedToMarkNotificationAsRead(notificationIdentifier: notificationIdentifier, errorDescription: error.localizedDescription)
            debugPrint("Error marking note as read: \(error)")
        }
    }

    /// Retrieves the WPCOM OAuth Token, meant for Extension usage.
    ///
    /// - Returns: the token if found; `nil` otherwise
    ///
    func readExtensionToken() -> String? {
        guard let oauthToken = try? SFHFKeychainUtils.getPasswordForUsername(WPNotificationContentExtensionKeychainTokenKey,
                                                                           andServiceName: WPNotificationContentExtensionKeychainServiceName,
                                                                           accessGroup: WPAppKeychainAccessGroup) else {
            debugPrint("Unable to retrieve Notification Content Extension OAuth token")
            return nil
        }

        return oauthToken
    }

    /// Retrieves the WPCOM username, meant for Extension usage.
    ///
    /// - Returns: the username if found; `nil` otherwise
    ///
    func readExtensionUsername() -> String? {
        guard let username = try? SFHFKeychainUtils.getPasswordForUsername(WPNotificationContentExtensionKeychainUsernameKey,
                                                                           andServiceName: WPNotificationContentExtensionKeychainServiceName,
                                                                           accessGroup: WPAppKeychainAccessGroup) else {
            debugPrint("Unable to retrieve Notification Content Extension username")
            return nil
        }

        return username
    }
}
