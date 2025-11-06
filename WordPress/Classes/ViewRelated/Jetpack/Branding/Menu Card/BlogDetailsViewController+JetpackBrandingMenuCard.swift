import Foundation

extension BlogDetailsViewController {

    @objc public var shouldShowTopJetpackBrandingMenuCard: Bool {
        let presenter = JetpackBrandingMenuCardPresenter(blog: self.blog)
        return presenter.shouldShowTopCard()
    }

    @objc public var shouldShowBottomJetpackBrandingMenuCard: Bool {
        let presenter = JetpackBrandingMenuCardPresenter(blog: self.blog)
        return presenter.shouldShowBottomCard()
    }

    private func showJetpackOverlay() {
        let presenter = JetpackBrandingMenuCardPresenter(blog: blog)
        JetpackFeaturesRemovalCoordinator.presentOverlayIfNeeded(in: self, source: .card, blog: blog)
        presenter.trackCardTapped()
    }

    func reloadTableView() {
        configureTableViewData()
        reloadTableViewPreservingSelection()
    }
}
