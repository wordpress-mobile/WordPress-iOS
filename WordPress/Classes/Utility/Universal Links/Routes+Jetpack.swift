struct JetpackRoute: Route {
    let path = "/app"
    let section: DeepLinkSection? = nil
    let action: NavigationAction = MeNavigationAction.root
}

extension JetpackRoute: NavigationAction {
    func perform(_ values: [String: String], source: UIViewController?, router: LinkRouter) {
        // We don't care where it opens in the app as long as it opens the app.
        // If we handle deferred linking only then it would be relevant.
    }
}
