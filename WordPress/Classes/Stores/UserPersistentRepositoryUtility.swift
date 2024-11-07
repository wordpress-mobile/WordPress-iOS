import Foundation

private enum UPRUConstants {
    static let promptKey = "onboarding_notifications_prompt_displayed"
    static let questionKey = "onboarding_question_selection"
    static let notificationPrimerAlertWasDisplayed = "NotificationPrimerAlertWasDisplayed"
    static let notificationsTabAccessCount = "NotificationsTabAccessCount"
    static let notificationPrimerInlineWasAcknowledged = "notificationPrimerInlineWasAcknowledged"
    static let secondNotificationsAlertCount = "secondNotificationsAlertCount"
    static let hasShownCustomAppIconUpgradeAlert = "custom-app-icon-upgrade-alert-shown"
    static let savedPostsPromoWasDisplayed = "SavedPostsV1PromoWasDisplayed"
    static let currentAnnouncementsKey = "currentAnnouncements"
    static let currentAnnouncementsDateKey = "currentAnnouncementsDate"
    static let announcementsVersionDisplayedKey = "announcementsVersionDisplayed"
    static let isJPContentImportCompleteKey = "jetpackContentImportComplete"
    static let jetpackContentMigrationStateKey = "jetpackContentMigrationState"
    static let mediaAspectRatioModeEnabledKey = "mediaAspectRatioModeEnabled"
    static let readerSidebarSelectionKey = "readerSidebarSelectionKey"
    static let isReaderSelectedKey = "isReaderSelectedKey"
    static let readerSearchHistoryKey = "readerSearchHistoryKey"
    static let readerDidSelectInterestsKey = "readerDidSelectInterestsKey"
}

protocol UserPersistentRepositoryUtility: AnyObject {
    var onboardingNotificationsPromptDisplayed: Bool { get set }
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

    var savedPostsPromoWasDisplayed: Bool {
        get {
            return UserPersistentStoreFactory.instance().bool(forKey: UPRUConstants.savedPostsPromoWasDisplayed)
        }
        set {
            UserPersistentStoreFactory.instance().set(newValue, forKey: UPRUConstants.savedPostsPromoWasDisplayed)
        }
    }

    var announcements: [Announcement]? {
        get {
            guard let encodedAnnouncements = UserPersistentStoreFactory.instance().object(forKey: UPRUConstants.currentAnnouncementsKey) as? Data,
                  let announcements = try? PropertyListDecoder().decode([Announcement].self, from: encodedAnnouncements) else {
                return nil
            }
            return announcements
        }

        set {
            guard let announcements = newValue, let encodedAnnouncements = try? PropertyListEncoder().encode(announcements) else {
                UserPersistentStoreFactory.instance().removeObject(forKey: UPRUConstants.currentAnnouncementsKey)
                UserPersistentStoreFactory.instance().removeObject(forKey: UPRUConstants.currentAnnouncementsDateKey)
                return
            }
            UserPersistentStoreFactory.instance().set(encodedAnnouncements, forKey: UPRUConstants.currentAnnouncementsKey)
            UserPersistentStoreFactory.instance().set(Date(), forKey: UPRUConstants.currentAnnouncementsDateKey)
        }
    }

    var announcementsDate: Date? {
        UserPersistentStoreFactory.instance().object(forKey: UPRUConstants.currentAnnouncementsDateKey) as? Date
    }

    var announcementsVersionDisplayed: String? {
        get {
            UserPersistentStoreFactory.instance().string(forKey: UPRUConstants.announcementsVersionDisplayedKey)
        }
        set {
            UserPersistentStoreFactory.instance().set(newValue, forKey: UPRUConstants.announcementsVersionDisplayedKey)
        }
    }

    var jetpackContentMigrationState: MigrationState {
        get {
            let repository = UserPersistentStoreFactory.instance()
            if let value = repository.string(forKey: UPRUConstants.jetpackContentMigrationStateKey) {
                return MigrationState(rawValue: value) ?? .notStarted
            } else if repository.bool(forKey: UPRUConstants.isJPContentImportCompleteKey) {
                // Migrate the value of the old `isJPContentImportCompleteKey` to `jetpackContentMigrationStateKey`
                let state = MigrationState.completed
                repository.set(state.rawValue, forKey: UPRUConstants.jetpackContentMigrationStateKey)
                repository.set(nil, forKey: UPRUConstants.isJPContentImportCompleteKey)
                return state
            } else {
                return .notStarted
            }
        } set {
            UserPersistentStoreFactory.instance().set(newValue.rawValue, forKey: UPRUConstants.jetpackContentMigrationStateKey)
        }
    }

    var isMediaAspectRatioModeEnabled: Bool {
        get {
            let repository = UserPersistentStoreFactory.instance()
            if let value = repository.object(forKey: UPRUConstants.mediaAspectRatioModeEnabledKey) as? Bool {
                return value
            }
            return UIDevice.current.userInterfaceIdiom == .pad
        }
        set {
            UserPersistentStoreFactory.instance().set(newValue, forKey: UPRUConstants.mediaAspectRatioModeEnabledKey)
        }
    }

    var isReaderSelected: Bool {
        get {
            UserPersistentStoreFactory.instance().bool(forKey: UPRUConstants.isReaderSelectedKey)
        }
        set {
            UserPersistentStoreFactory.instance().set(newValue, forKey: UPRUConstants.isReaderSelectedKey)
        }
    }

    var readerSidebarSelection: ReaderStaticScreen? {
        get {
            let repository = UserPersistentStoreFactory.instance()
            return repository.string(forKey: UPRUConstants.readerSidebarSelectionKey)
                .flatMap(ReaderStaticScreen.init)
        }
        set {
            let repository = UserPersistentStoreFactory.instance()
            repository.set(newValue?.rawValue, forKey: UPRUConstants.readerSidebarSelectionKey)
        }
    }

    var readerSearchHistory: [String] {
        get {
            UserPersistentStoreFactory.instance()
                .array(forKey: UPRUConstants.readerSearchHistoryKey) as? [String] ?? []
        }
        set {
            UserPersistentStoreFactory.instance()
                .set(newValue, forKey: UPRUConstants.readerSearchHistoryKey)
        }
    }

    var readerDidSelectInterestsKey: Bool {
        get {
            UserPersistentStoreFactory.instance().bool(forKey: UPRUConstants.readerDidSelectInterestsKey)
        }
        set {
            UserPersistentStoreFactory.instance().set(newValue, forKey: UPRUConstants.readerDidSelectInterestsKey)
        }
    }
}
