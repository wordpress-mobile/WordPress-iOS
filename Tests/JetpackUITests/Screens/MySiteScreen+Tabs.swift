import XCTest

/// Navigation to the app's other tabs.
extension MySiteScreen {
    func goToReader() throws -> ReaderScreen {
        try selectTab("tabbar_reader")
        return try ReaderScreen(app: app)
    }

    func goToNotifications() throws -> NotificationsScreen {
        try selectTab("tabbar_notifications")
        return try NotificationsScreen(app: app)
    }

    func goToMe() throws -> MeScreen {
        try selectTab("tabbar_me")
        return try MeScreen(app: app)
    }

    /// Taps a tab until the tab bar shows it selected, up to three times. See `tap(_:until:)` for
    /// why it taps the middle of the tab's frame.
    private func selectTab(_ identifier: String) throws {
        let tab = app.buttons[identifier]
        try waitFor(tab)
        for attempt in 1...3 {
            if attempt > 1 {
                logRetry(of: tab, attempt: attempt)
            }
            tapMiddle(of: tab)
            if tab.poll(timeout: 5, until: { $0.isSelected }) {
                return
            }
        }
        try waitForSelection(of: tab)
    }
}
