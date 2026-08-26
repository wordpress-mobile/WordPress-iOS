import AppIntents

/// Surfaces the navigation intents in the Shortcuts app and Siri without any user setup.
struct JetpackAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: NewPostIntent(),
            phrases: [
                "Create a new post in \(.applicationName)",
                "Write a new post in \(.applicationName)",
                "New \(.applicationName) post"
            ],
            shortTitle: LocalizedStringResource(
                "New Post",
                defaultValue: "New Post",
                table: "Localizable",
                comment: "Short title of the New Post shortcut tile in Spotlight and the Shortcuts app."
            ),
            systemImageName: "square.and.pencil"
        )
        AppShortcut(
            intent: OpenNotificationsIntent(),
            phrases: [
                "Open my \(.applicationName) notifications",
                "Show my \(.applicationName) notifications"
            ],
            shortTitle: LocalizedStringResource(
                "Notifications",
                defaultValue: "Notifications",
                table: "Localizable",
                comment: "Short title of the Notifications shortcut tile in Spotlight and the Shortcuts app."
            ),
            systemImageName: "bell"
        )
        AppShortcut(
            intent: OpenStatsIntent(),
            phrases: [
                "Open my \(.applicationName) stats",
                "Show my site stats in \(.applicationName)"
            ],
            shortTitle: LocalizedStringResource(
                "Stats",
                defaultValue: "Stats",
                table: "Localizable",
                comment: "Short title of the Stats shortcut tile in Spotlight and the Shortcuts app."
            ),
            systemImageName: "chart.bar"
        )
        AppShortcut(
            intent: OpenReaderIntent(),
            phrases: [
                "Open the \(.applicationName) Reader",
                "Open Reader in \(.applicationName)"
            ],
            shortTitle: LocalizedStringResource(
                "Reader",
                defaultValue: "Reader",
                table: "Localizable",
                comment: "Short title of the Reader shortcut tile in Spotlight and the Shortcuts app."
            ),
            systemImageName: "book"
        )
    }
}
