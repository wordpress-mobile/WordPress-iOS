// MARK: - Push Notification Primer
//
extension NotificationsViewController {
    private struct Analytics {
        static let locationKey = "location"
        static let inlineKey = "inline"
    }

    func setupPrimeForPush() {
        defer {
            WPAnalytics.track(.pushNotificationPrimerSeen, withProperties: [Analytics.locationKey: Analytics.inlineKey])
        }

        inlinePromptView.setupHeading(NSLocalizedString("We'll notify you when you get followers, comments, and likes.",
                                                        comment: "This is the string we display when asking the user to approve push notifications"))
        let yesTitle = NSLocalizedString("Allow notifications",
                                         comment: "Button label for approving our request to allow push notifications")
        let noTitle = NSLocalizedString("Not now",
                                        comment: "Button label for denying our request to allow push notifications")

        inlinePromptView.setupYesButton(title: yesTitle) { [weak self] button in
            defer {
                WPAnalytics.track(.pushNotificationPrimerAllowTapped, withProperties: [Analytics.locationKey: Analytics.inlineKey])
            }
            InteractiveNotificationsManager.shared.requestAuthorization {
                DispatchQueue.main.async {
                    self?.hideInlinePrompt(delay: 0.0)
                    UserDefaults.standard.notificationPrimerInlineWasAcknowledged = true
                }
            }
        }

        inlinePromptView.setupNoButton(title: noTitle) { [weak self] button in
            defer {
                WPAnalytics.track(.pushNotificationPrimerNoTapped, withProperties: [Analytics.locationKey: Analytics.inlineKey])
            }
            self?.hideInlinePrompt(delay: 0.0)
            UserDefaults.standard.notificationPrimerInlineWasAcknowledged = true
        }
    }
}

// MARK: - User Defaults for Push Notifications

extension UserDefaults {
    private enum Keys: String {
        case notificationPrimerInlineWasAcknowledged = "notificationPrimerInlineWasAcknowledged"
    }

    var notificationPrimerInlineWasAcknowledged: Bool {
        get {
            return bool(forKey: Keys.notificationPrimerInlineWasAcknowledged.rawValue)
        }
        set {
            set(newValue, forKey: Keys.notificationPrimerInlineWasAcknowledged.rawValue)
        }
    }
}
