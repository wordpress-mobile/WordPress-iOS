struct MigrationActionsViewConfiguration {

    let primaryTitle: String?
    let secondaryTitle: String?
    let primaryHandler: (() -> Void)?
    let secondaryHandler: (() -> Void)?
}

extension MigrationActionsViewConfiguration {

    init(step: MigrationStep, primaryHandler: (() -> Void)? = nil, secondaryHandler: (() -> Void)? = nil) {
        self.primaryHandler = primaryHandler
        self.secondaryHandler = secondaryHandler
        self.primaryTitle = Appearance.primaryTitle(for: step)
        self.secondaryTitle = Appearance.secondaryTitle(for: step)
    }
}

private extension MigrationActionsViewConfiguration {

    enum Appearance {

        static func primaryTitle(for step: MigrationStep) -> String? {
            switch step {
            case .welcome, .notifications:
                return Appearance.defaultPrimaryTitle
            case .done:
                return Appearance.donePrimaryTitle
            case.dismiss:
                return nil
            }
        }

        static func secondaryTitle(for step: MigrationStep) -> String? {
            switch step {
            case .welcome:
                return Appearance.welcomeSecondaryTitle
            case .notifications:
                return Appearance.notificationsSecondaryTitle
            default:
                return nil
            }
        }

        static let defaultPrimaryTitle = NSLocalizedString("Continue",
                                                           value: "Continue",
                                                           comment: "The primary button title in the migration welcome and notifications screens.")

        static let donePrimaryTitle = NSLocalizedString("migrationDone.actions.primaryTitle",
                                                        value: "Let's go",
                                                        comment: "Primary button title in the migration done screen.")

        static let welcomeSecondaryTitle = NSLocalizedString("Need help?",
                                                             comment: "The secondary button title in the migration welcome screen")

        static let notificationsSecondaryTitle = NSLocalizedString("migration.notifications.actions.secondary.title",
                                                                   value: "Decide later",
                                                                   comment: "Secondary button title in the migration notifications screen.")
    }
}
