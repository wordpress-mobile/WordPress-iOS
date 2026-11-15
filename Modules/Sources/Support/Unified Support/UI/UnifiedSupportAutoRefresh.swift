import SwiftUI

extension View {
    /// Runs `action` whenever the app comes back from the background, and optionally repeats it while the screen
    /// is the one on top.
    ///
    /// The screen stops refreshing when the user opens another one, so a conversation being read doesn't have the
    /// list changing behind it.
    ///
    /// - Parameter interval: How often to repeat the action, or `nil` to only run it on returning from the
    ///   background. A list the user isn't looking at has nothing to gain from polling.
    func unifiedSupportAutoRefresh(
        every interval: Duration? = nil,
        action: @escaping () async -> Void
    ) -> some View {
        modifier(UnifiedSupportAutoRefreshModifier(interval: interval, action: action))
    }
}

private struct UnifiedSupportAutoRefreshModifier: ViewModifier {

    let interval: Duration?
    let action: () async -> Void

    @State private var isOnScreen = false

    func body(content: Content) -> some View {
        content
            .onAppear { isOnScreen = true }
            .onDisappear { isOnScreen = false }
            .task(id: isOnScreen) {
                guard isOnScreen, let interval else {
                    return
                }
                while !Task.isCancelled {
                    try? await Task.sleep(for: interval)
                    guard !Task.isCancelled else {
                        return
                    }
                    await action()
                }
            }
            .task(id: isOnScreen) {
                guard isOnScreen else {
                    return
                }
                // The app uses `UIScene`, so `scenePhase` doesn't change here when it goes to the background.
                let foregroundNotifications = NotificationCenter.default.notifications(
                    named: UIApplication.willEnterForegroundNotification
                )
                for await _ in foregroundNotifications {
                    await action()
                }
            }
    }
}
