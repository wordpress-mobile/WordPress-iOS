import WordPressUI
import SwiftUI

extension NotificationsViewController {
    private struct Analytics {
        static let locationKey = "location"
        static let alertKey = "alert"
    }

    static func makeNotificationPrimerAlertController(approveAction: @escaping (() -> Void)) -> UIViewController {
        makeNotificationAuthorizationAlertController(
            title: Strings.firstAlertTitleText,
            description: Strings.firstAlertBodyText,
            allowButtonText: Strings.firstAllowButtonText,
            seenEvent: .pushNotificationsPrimerSeen,
            allowEvent: .pushNotificationsPrimerAllowTapped,
            noEvent: .pushNotificationsPrimerNoTapped,
            approveAction: approveAction
        )
    }

    static func makeNotificationSecondAlertController(approveAction: @escaping (() -> Void)) -> UIViewController {
        makeNotificationAuthorizationAlertController(
            title: Strings.secondAlertTitleText,
            description: Strings.secondAlertBodyText,
            allowButtonText: Strings.secondAllowButtonText,
            seenEvent: .secondNotificationsAlertSeen,
            allowEvent: .secondNotificationsAlertAllowTapped,
            noEvent: .secondNotificationsAlertNoTapped,
            approveAction: approveAction
        )
    }

    private static func makeNotificationAuthorizationAlertController(
        title: String,
        description: String,
        allowButtonText: String,
        seenEvent: WPAnalyticsEvent,
        allowEvent: WPAnalyticsEvent,
        noEvent: WPAnalyticsEvent,
        approveAction: @escaping (() -> Void)
    ) -> UIViewController {
        let hostVC = UIHostingController<AnyView>(rootView: AnyView(EmptyView()))

        let alert = AlertView {
            AlertHeaderView(
                title: title,
                description: description
            )
        } content: {
            ScaledImage("wpl-bell", height: 78)
                .foregroundStyle(.secondary)
        } actions: {
            Button {
                approveAction()
                WPAnalytics.track(allowEvent, properties: [Analytics.locationKey: Analytics.alertKey])
            } label: {
                Text(allowButtonText)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.extraLarge)

            Button(Strings.notNowText) { [weak hostVC] in
                WPAnalytics.track(noEvent, properties: [Analytics.locationKey: Analytics.alertKey])
                hostVC?.presentingViewController?.dismiss(animated: true)
            }
        }.onAppear {
            WPAnalytics.track(seenEvent, properties: [Analytics.locationKey: Analytics.alertKey])
        }

        hostVC.rootView = AnyView(alert)
        hostVC.sheetPresentationController?.detents = [.medium()]
        return hostVC
    }
}

private struct Strings {
    static let firstAlertTitleText = NSLocalizedString("notifications.primer.firstAlert.title", value: "Stay in the loop", comment: "Title of the first alert preparing users to grant permission for us to send them push notifications.")
    static let firstAlertBodyText = NSLocalizedString("notifications.primer.firstAlert.body", value: "We'll notify you when you get new followers, comments, and likes. Would you like to allow push notifications?", comment: "Body text of the first alert preparing users to grant permission for us to send them push notifications.")
    static let firstAllowButtonText = NSLocalizedString("notifications.primer.firstAlert.allowButton", value: "Allow notifications", comment: "Allow button title shown in alert preparing users to grant permission for us to send them push notifications.")
    static let secondAlertTitleText = NSLocalizedString("notifications.primer.secondAlert.title", value: "Get your notifications faster", comment: "Title of the second alert preparing users to grant permission for us to send them push notifications.")
    static let secondAlertBodyText = NSLocalizedString("notifications.primer.secondAlert.body", value: "Learn about new comments, likes, and follows in seconds.", comment: "Body text of the first alert preparing users to grant permission for us to send them push notifications.")
    static let secondAllowButtonText = NSLocalizedString("notifications.primer.secondAlert.allowButton", value: "Allow push notifications", comment: "Allow button title shown in alert preparing users to grant permission for us to send them push notifications.")
    static let notNowText = NSLocalizedString("notifications.primer.notNowButton", value: "Not now", comment: "Not now button title shown in alert preparing users to grant permission for us to send them push notifications.")
}
