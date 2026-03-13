import WordPressData

extension Blog {

    func areBloggingRemindersAllowed(
        jetpackNotificationMigrationService: JetpackNotificationMigrationService = .shared
    ) -> Bool {
        return isUserCapableOf(.editPosts) && jetpackNotificationMigrationService.shouldPresentNotifications()
    }
}
