/// Triggers the data export process on WordPress.
///
/// Note: this is only meant to be used in WordPress!
///
struct WordPressExportRoute: Route {
    let path = "/export-213"
    let section: DeepLinkSection? = nil
    var action: NavigationAction {
        return self
    }
}

extension WordPressExportRoute: NavigationAction {
    func perform(_ values: [String: String], source: UIViewController?, router: LinkRouter) {
        guard AppConfiguration.isWordPress else {
            return
        }

        ContentMigrationCoordinator.shared.startAndDo { _ in
            // Regardless of the result, redirect the user back to Jetpack.
            let jetpackUrl: URL? = {
                var components = URLComponents()
                components.scheme = JetpackNotificationMigrationService.jetpackScheme
                components.host = JetpackImportRoute().path.removingPrefix("/")
                return components.url
            }()

            guard let url = jetpackUrl,
                  UIApplication.shared.canOpenURL(url) else {
                DDLogError("WordPressExportRoute: Cannot redirect back to the Jetpack app.")
                return
            }

            UIApplication.shared.open(url)
        }
    }
}
