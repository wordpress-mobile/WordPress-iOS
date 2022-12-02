/// Triggers the migration process in Jetpack.
///
/// Note: This route should only be used from Jetpack!
///
struct JetpackImportRoute: Route {
    let path = "/import-213"
    let section: DeepLinkSection? = nil
    var action: NavigationAction {
        return self
    }
}

extension JetpackImportRoute: NavigationAction {
    func perform(_ values: [String: String], source: UIViewController?, router: LinkRouter) {
        guard AppConfiguration.isJetpack,
              let appDelegate = WordPressAppDelegate.shared else {
            return
        }

        // Force Jetpack to restart the migration process and reconstruct the UI.
        appDelegate.windowManager.showUI()
    }
}
