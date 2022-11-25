import Foundation

final class MigrationDeleteWordPressViewModel {

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
            "migration.deleteWordpress.title",
            value: "You no longer need the WordPress app",
            comment: "The title in the Delete WordPress screen"
        )
        static let description = NSLocalizedString(
            "migration.deleteWordpress.description",
            value: "It looks like you still have the WordPress app installed. We recommend you delete the WordPress app to avoid data conflicts.",
            comment: "The description in the Delete WordPress screen"
        )
        static let primaryAction = NSLocalizedString(
            "migration.deleteWordpress.primaryButton",
            value: "Got it",
            comment: "The primary button title in the Delete WordPress screen"
        )
        static let secondaryAction = NSLocalizedString(
            "Need help?",
            value: "Need help?",
            comment: "The secondary button title in the Delete WordPress screen"
        )
    }

    class Actions {
        var primary: (() -> Void)?
        var secondary: (() -> Void)?
    }
}
