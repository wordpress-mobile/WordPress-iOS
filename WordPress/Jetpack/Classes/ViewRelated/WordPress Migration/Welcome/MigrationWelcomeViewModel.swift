import UIKit

final class MigrationWelcomeViewModel: MigrationStepViewModel {

    // MARK: - Properties

    let gravatarEmail: String

    let blogListDataSource: BlogListDataSource

    // MARK: - Init

    init(account: WPAccount, primaryAction: @escaping () -> Void) {
        self.gravatarEmail = account.email

        self.blogListDataSource = BlogListDataSource()
        self.blogListDataSource.loggedIn = true
        self.blogListDataSource.account = account

        let primaryAction = Action(title: Strings.primaryButtonTitle, handler: primaryAction)
        let secondaryAction = Action(title: Strings.secondaryButtonTitle, handler: {})
        let actions = Actions(primary: primaryAction, secondary: secondaryAction)

        let secondaryDescription = Strings.secondaryDescription(plural: blogListDataSource.visibleBlogsCount > 1)
        let descriptions = Descriptions(primary: Strings.primaryDescription, secondary: secondaryDescription)

        super.init(
            title: Strings.title,
            image: UIImage(named: "wp-migration-welcome"),
            descriptions: descriptions,
            actions: actions
        )
    }

    // MARK: - Constants

    struct Strings {

        static let title = NSLocalizedString(
            "migration.welcome.title",
            value: "Welcome to Jetpack!",
            comment: "The title in the migration welcome screen"
        )

        static let primaryDescription = NSLocalizedString(
            "migration.welcome.primaryDescription",
            value: "It looks like you’re switching from the WordPress app.",
            comment: "The primary description in the migration welcome screen"
        )

        static func secondaryDescription(plural: Bool) -> String {
            let comment = "The secondary description in the migration welcome screen"
            let siteWord = plural ? "sites" : "site"
            let value = "We found your \(siteWord). Continue to transfer all your data and sign in to Jetpack automatically."
            if plural {
                let comment = "The plural form of the secondary description in the migration welcome screen"
                return NSLocalizedString("migration.welcome.secondaryDescription.plural", value: value, comment: comment)
            } else {
                let comment = "The singular form of the secondary description in the migration welcome screen"
                return NSLocalizedString("migration.welcome.secondaryDescription.singular", value: value, comment: comment)
            }
        }

        static let primaryButtonTitle = NSLocalizedString(
            "Continue",
            value: "Continue",
            comment: "The primary button title in the migration welcome screen"
        )

        static let secondaryButtonTitle = NSLocalizedString(
            "Need help?",
            comment: "The secondary button title in the migration welcome screen"
        )
    }
}
