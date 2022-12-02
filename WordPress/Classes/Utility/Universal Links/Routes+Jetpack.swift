struct JetpackRoute: Route {
    let path = "/app"
    let section: DeepLinkSection? = nil
    var action: NavigationAction {
        return self
    }
}

extension JetpackRoute: NavigationAction {
    func perform(_ values: [String: String], source: UIViewController?, router: LinkRouter) {
        // We don't care where it opens in the app as long as it opens the app.
        // If we handle deferred linking only then it would be relevant.
    }
}

// MARK: - Trigger Export on WordPress

struct WordPressExportRoute: Route {
    let path = "/export-213"
    let section: DeepLinkSection? = nil
    var action: NavigationAction {
        return self
    }
}

extension WordPressExportRoute: NavigationAction {
    func perform(_ values: [String: String], source: UIViewController?, router: LinkRouter) {
        // Trigger the export process
        ContentMigrationCoordinator.shared.startAndDo { _ in
            // Regardless of the result, redirect the user back to Jetpack.
            let jetpackUrl: URL? = {
                var components = URLComponents()
                components.scheme = JetpackNotificationMigrationService.jetpackScheme
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
