import Combine
import Foundation

class JetpackWindowManager: WindowManager {
    /// receives migration flow updates in order to dismiss it when needed.
    private var cancellable: AnyCancellable?

    override func showUI(for blog: Blog?) {
        // If the user is logged in and has blogs sync'd to their account
        if AccountHelper.isLoggedIn && AccountHelper.hasBlogs {
            shouldShowMigrationUI ? showMigrationUI(blog) : showAppUI(for: blog)
            return
        }

        // Show the sign in UI if the user isn't logged in
        guard AccountHelper.isLoggedIn else {
            showSignInUI()
            return
        }

        // If the user doesn't have any blogs, but they're still logged in, log them out
        // the `logOutDefaultWordPressComAccount` method will trigger the `showSignInUI` automatically
        AccountHelper.logOutDefaultWordPressComAccount()
    }

    private func showMigrationUI(_ blog: Blog?) {
        let container = MigrationDependencyContainer()
        cancellable = container.migrationCoordinator.$currentStep
            .receive(on: DispatchQueue.main)
            .sink { [weak self] step in
                guard step == .dismiss else {
                    return
                }
                self?.switchToAppUI(for: blog)
            }
        self.show(container.makeInitialViewController())
    }

    private func switchToAppUI(for blog: Blog?) {
        cancellable = nil
        showAppUI(for: blog)
    }

    // TODO: Add logic in here to trigger migration UI if needed
    private var shouldShowMigrationUI: Bool {
        false
    }
}
