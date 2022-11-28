import Foundation

extension JetpackRoute: NavigationAction {

    func perform(_ values: [String: String], source: UIViewController?, router: LinkRouter) {
        guard FeatureFlag.contentMigration.enabled && !AccountHelper.isLoggedIn else {
            return
        }
        ContentMigrationCoordinator.shared.importData { result in
            guard case .success = result,
                  AccountHelper.isLoggedIn,
                  AccountHelper.hasBlogs,
                  let windowManager = WordPressAppDelegate.shared?.windowManager as? JetpackWindowManager
            else {
                return
            }
            windowManager.showMigrationUI()
        }
    }
}
