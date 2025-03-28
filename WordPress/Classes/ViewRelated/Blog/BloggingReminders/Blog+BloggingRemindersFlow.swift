extension Blog {

    func areBloggingRemindersAllowed(
        jetpackNotificationMigrationService: JetpackNotificationMigrationService = .shared
    ) -> Bool {
        return isUserCapableOf(.EditPosts) && jetpackNotificationMigrationService.shouldPresentNotifications()
    }
}
