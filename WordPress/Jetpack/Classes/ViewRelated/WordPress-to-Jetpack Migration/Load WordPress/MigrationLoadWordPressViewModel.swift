import Foundation

final class MigrationLoadWordPressViewModel {

    // MARK: - Configuration

    let header: MigrationHeaderConfiguration
    let content: MigrationCenterViewConfiguration
    let actions: MigrationActionsViewConfiguration

    // MARK: - Init

    init(actions: Actions) {
        self.header = .init(
            title: Strings.title,
            image: UIImage(named: "wp-migration-welcome"),
            primaryDescription: Strings.description,
            secondaryDescription: nil
        )
        self.content = .init(step: .done)
        self.actions = .init(
            primaryTitle: Strings.primaryAction,
            secondaryTitle: Strings.secondaryAction,
            primaryHandler: { actions.primary?() },
            secondaryHandler: { actions.secondary?() }
        )
    }

    // MARK: - Types

    enum Strings {
        static let title = NSLocalizedString(
            "migration.loadWordpress.title",
            value: "Welcome to Jetpack!",
            comment: "The title in the Load WordPress screen"
        )
        static let description = NSLocalizedString(
            "migration.loadWordpress.description",
            value: "It looks like you have the WordPress app installed.\n\nWould you like to transfer your data from the WordPress app and sign in automatically?",
            comment: "The description in the Load WordPress screen"
        )
        static let primaryAction = NSLocalizedString(
            "migration.loadWordpress.primaryButton",
            value: "Open WordPress",
            comment: "The primary button title in the Load WordPress screen"
        )
        static let secondaryAction = NSLocalizedString(
            "migration.loadWordpress.secondaryButton",
            value: "No thanks",
            comment: "The secondary button title in the Load WordPress screen"
        )
    }

    class Actions {
        var primary: (() -> Void)?
        var secondary: (() -> Void)?
    }
}
