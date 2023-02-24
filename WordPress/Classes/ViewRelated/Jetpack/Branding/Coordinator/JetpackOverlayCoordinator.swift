protocol JetpackOverlayCoordinator {
    func navigateToPrimaryRoute()
    func navigateToSecondaryRoute()
    func navigateToLinkRoute(url: URL, source: String)
}
