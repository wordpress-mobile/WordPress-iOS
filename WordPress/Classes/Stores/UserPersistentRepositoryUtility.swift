import Foundation

private enum UPRUConstants {
    static let promptKey = "onboarding_notifications_prompt_displayed"
    static let questionKey = "onboarding_question_selection"
    static let notificationPrimerAlertWasDisplayed = "NotificationPrimerAlertWasDisplayed"
    static let notificationsTabAccessCount = "NotificationsTabAccessCount"
    static let notificationPrimerInlineWasAcknowledged = "notificationPrimerInlineWasAcknowledged"
    static let secondNotificationsAlertCount = "secondNotificationsAlertCount"
    static let hasShownCustomAppIconUpgradeAlert = "custom-app-icon-upgrade-alert-shown"
    static let createButtonTooltipWasDisplayed = "CreateButtonTooltipWasDisplayed"
    static let createButtonTooltipDisplayCount = "CreateButtonTooltipDisplayCount"
}

protocol UserPersistentRepositoryUtility: AnyObject {
    var onboardingNotificationsPromptDisplayed: Bool { get set }
    var onboardingQuestionSelected: OnboardingOption? { get set }
    var notificationPrimerAlertWasDisplayed: Bool { get set }
}

extension UserPersistentRepositoryUtility {
    var onboardingNotificationsPromptDisplayed: Bool {
        get {
            UserPersistentStoreFactory.instance().bool(forKey: UPRUConstants.promptKey)
        }
        set {
            UserPersistentStoreFactory.instance().set(newValue, forKey: UPRUConstants.promptKey)
        }
    }

    var onboardingQuestionSelected: OnboardingOption? {
        get {
            if let str = UserPersistentStoreFactory.instance().string(forKey: UPRUConstants.questionKey) {
                return OnboardingOption(rawValue: str)
            }

            return nil
        }
        set {
            UserPersistentStoreFactory.instance().set(newValue?.rawValue, forKey: UPRUConstants.questionKey)
        }
    }

    var notificationPrimerAlertWasDisplayed: Bool {
        get {
            UserPersistentStoreFactory.instance().bool(forKey: UPRUConstants.notificationPrimerAlertWasDisplayed)
        }
        set {
            UserPersistentStoreFactory.instance().set(newValue, forKey: UPRUConstants.notificationPrimerAlertWasDisplayed)
        }
    }

    var notificationsTabAccessCount: Int {
        get {
            UserPersistentStoreFactory.instance().integer(forKey: UPRUConstants.notificationsTabAccessCount)
        }

        set {
            UserPersistentStoreFactory.instance().set(newValue, forKey: UPRUConstants.notificationsTabAccessCount)
        }
    }

    var welcomeNotificationSeenKey: String {
        return "welcomeNotificationSeen"
    }

    var notificationPrimerInlineWasAcknowledged: Bool {
        get {
            UserPersistentStoreFactory.instance().bool(forKey: UPRUConstants.notificationPrimerInlineWasAcknowledged)
        }
        set {
            UserPersistentStoreFactory.instance().set(newValue, forKey: UPRUConstants.notificationPrimerInlineWasAcknowledged)
        }
    }

    var secondNotificationsAlertCount: Int {
        get {
            UserPersistentStoreFactory.instance().integer(forKey: UPRUConstants.secondNotificationsAlertCount)
        }
        set {
            UserPersistentStoreFactory.instance().set(newValue, forKey: UPRUConstants.secondNotificationsAlertCount)
        }
    }

    var hasShownCustomAppIconUpgradeAlert: Bool {
        get {
            UserPersistentStoreFactory.instance().bool(forKey: UPRUConstants.hasShownCustomAppIconUpgradeAlert)
        }
        set {
            UserPersistentStoreFactory.instance().set(newValue, forKey: UPRUConstants.hasShownCustomAppIconUpgradeAlert)
        }
    }

    var createButtonTooltipDisplayCount: Int {
        get {
            UserPersistentStoreFactory.instance().integer(forKey: UPRUConstants.createButtonTooltipDisplayCount)
        }
        set {
            UserPersistentStoreFactory.instance().set(newValue, forKey: UPRUConstants.createButtonTooltipDisplayCount)
        }
    }

    var createButtonTooltipWasDisplayed: Bool {
        get {
            UserPersistentStoreFactory.instance().bool(forKey: UPRUConstants.createButtonTooltipWasDisplayed)
        }
        set {
            UserPersistentStoreFactory.instance().set(newValue, forKey: UPRUConstants.createButtonTooltipWasDisplayed)
        }
    }
}
