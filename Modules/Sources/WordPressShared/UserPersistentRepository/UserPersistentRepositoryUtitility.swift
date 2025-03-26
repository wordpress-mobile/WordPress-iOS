public protocol UserPersistentRepositoryUtility: AnyObject {
    var onboardingNotificationsPromptDisplayed: Bool { get set }
    var notificationPrimerAlertWasDisplayed: Bool { get set }
}

public enum UPRUConstants {
    static let promptKey = "onboarding_notifications_prompt_displayed"
    static let questionKey = "onboarding_question_selection"
    static let notificationPrimerAlertWasDisplayed = "NotificationPrimerAlertWasDisplayed"
    public static let notificationsTabAccessCount = "NotificationsTabAccessCount"
    public static let notificationPrimerInlineWasAcknowledged = "notificationPrimerInlineWasAcknowledged"
    public static let secondNotificationsAlertCount = "secondNotificationsAlertCount"
    public static let hasShownCustomAppIconUpgradeAlert = "custom-app-icon-upgrade-alert-shown"
    public static let savedPostsPromoWasDisplayed = "SavedPostsV1PromoWasDisplayed"
    public static let currentAnnouncementsKey = "currentAnnouncements"
    public static let currentAnnouncementsDateKey = "currentAnnouncementsDate"
    public static let announcementsVersionDisplayedKey = "announcementsVersionDisplayed"
    public static let isJPContentImportCompleteKey = "jetpackContentImportComplete"
    public static let jetpackContentMigrationStateKey = "jetpackContentMigrationState"
    public static let mediaAspectRatioModeEnabledKey = "mediaAspectRatioModeEnabled"
    public static let readerSidebarSelectionKey = "readerSidebarSelectionKey"
    public static let isReaderSelectedKey = "isReaderSelectedKey"
    public static let readerSearchHistoryKey = "readerSearchHistoryKey"
    public static let readerDidSelectInterestsKey = "readerDidSelectInterestsKey"
}

public extension UserPersistentRepositoryUtility {
    var onboardingNotificationsPromptDisplayed: Bool {
        get {
            UserPersistentStoreFactory.instance().bool(forKey: UPRUConstants.promptKey)
        }
        set {
            UserPersistentStoreFactory.instance().set(newValue, forKey: UPRUConstants.promptKey)
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
}
