struct DomainsManageRoute: Route {
    let path = "/domains/manage"
    let section: DeepLinkSection? = .me
    let action: NavigationAction = MeNavigationAction.allDomains
    let jetpackPowered: Bool = true
}

enum DomainsAction: NavigationAction {
    case allDomains

    func perform(_ values: [String: String] = [:], source: UIViewController? = nil, router: LinkRouter) {
        switch self {
        case .allDomains:
            RootViewCoordinator.sharedPresenter.navigateToAllDomains()
        }
    }
}
