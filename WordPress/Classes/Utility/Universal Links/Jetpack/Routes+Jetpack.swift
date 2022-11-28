struct JetpackRoute: Route {
    let path = "/app"
    let section: DeepLinkSection? = nil
    var action: NavigationAction {
        return self
    }
}
