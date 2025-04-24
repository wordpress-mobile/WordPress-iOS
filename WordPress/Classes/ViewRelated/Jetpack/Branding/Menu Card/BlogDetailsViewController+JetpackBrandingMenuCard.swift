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

    @objc public func jetpackCardSectionViewModel() -> BlogDetailsSection {
        let row = BlogDetailsRow()
        row.callback = { [weak self] in
            self?.showJetpackOverlay()
        }
        return BlogDetailsSection(
            title: nil,
            rows: [row],
            footerTitle: nil,
            category: .jetpackBrandingCard
        )
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
