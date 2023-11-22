struct MigrationHeaderConfiguration {

    let title: String?
    let image: UIImage?
    let primaryDescription: String?
    let secondaryDescription: String?
}

extension MigrationHeaderConfiguration {

    init(step: MigrationStep, multiSite: Bool = false) {
        image = Appearance.image(for: step)
        title = Appearance.title(for: step)
        primaryDescription = Appearance.primaryDescription(for: step)
        secondaryDescription = Appearance.secondaryDescription(for: step, multiSite: multiSite)
    }
}

private extension MigrationHeaderConfiguration {

    enum Appearance {
        static func image(for step: MigrationStep) -> UIImage? {
            switch step {
            case .welcome:
                return UIImage(named: "wp-migration-welcome")
            case .notifications:
                return UIImage(named: "wp-migration-notifications")
            case .done:
                return UIImage(named: "wp-migration-done")
            case .dismiss:
                return nil
            }
        }

        static func title(for step: MigrationStep) -> String? {
            switch step {
            case .welcome:
                return welcomeTitle
            case .notifications:
                return notificationsTitle
            case .done:
                return doneTitle
            case .dismiss:
                return nil
            }
        }

        static func primaryDescription(for step: MigrationStep) -> String? {
            switch step {
            case .welcome:
                return welcomePrimaryDescription
            case .notifications:
                return notificationsPrimaryDescription
            case .done:
                return donePrimaryDescription + "\n\n" + doneSecondaryDescription
            case .dismiss:
                return nil
            }
        }

        static func secondaryDescription(for step: MigrationStep, multiSite: Bool = false) -> String? {
            switch step {
            case .welcome:
                return welcomeSecondaryDescription(plural: multiSite)
            case .notifications:
                return JetpackNotificationMigrationService.shared.isMigrationSupported ? notificationsSecondaryDescription : nil
            case .done:
                return nil
            case .dismiss:
                return nil
            }
        }

        static let welcomeTitle = NSLocalizedString("migration.welcome.title",
                                                    value: "Welcome to Jetpack!",
                                                    comment: "The title in the migration welcome screen")

        static let notificationsTitle = NSLocalizedString("migration.notifications.title",
                                                          value: "Allow notifications to keep up with your site",
                                                          comment: "Title of the migration notifications screen.")

        static let doneTitle = NSLocalizedString("migration.done.title",
                                                 value: "Thanks for switching to Jetpack!",
                                                 comment: "Title of the migration done screen.")

        static let welcomePrimaryDescription = NSLocalizedString("migration.welcome.primaryDescription",
                                                                 value: "It looks like you’re switching from the WordPress app.",
                                                                 comment: "The primary description in the migration welcome screen")

        static let notificationsPrimaryDescription = NSLocalizedString("migration.notifications.primaryDescription",
                                                                       value: "You’ll get all the same notifications but now they’ll come from the Jetpack app.",
                                                                       comment: "Primary description in the migration notifications screen.")

        static let donePrimaryDescription = NSLocalizedString("migration.done.primaryDescription",
                                                              value: "We’ve transferred all your data and settings. Everything is right where you left it.",
                                                              comment: "Primary description in the migration done screen.")

        static let doneSecondaryDescription = NSLocalizedString("migration.done.secondaryDescription", value: "It's time to continue your WordPress journey on the Jetpack app!", comment: "Secondary description (second paragraph) in the migration done screen.")

        static let notificationsSecondaryDescription = NSLocalizedString("migration.notifications.secondaryDescription",
                                                                         value: "We’ll disable notifications for the WordPress app.",
                                                                         comment: "Secondary description in the migration notifications screen")

        static func welcomeSecondaryDescription(plural: Bool) -> String {
            if plural {
                return NSLocalizedString(
                    "migration.welcome.secondaryDescription.plural",
                    value: "We found your sites. Continue to transfer all your data and sign in to Jetpack automatically.",
                    comment: "The plural form of the secondary description in the migration welcome screen"
                )
            } else {
                return NSLocalizedString(
                    "migration.welcome.secondaryDescription.singular",
                    value: "We found your site. Continue to transfer all your data and sign in to Jetpack automatically.",
                    comment: "The singular form of the secondary description in the migration welcome screen"
                )
            }
        }
    }
}
