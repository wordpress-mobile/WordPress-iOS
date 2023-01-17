import Foundation

extension BlogDetailsViewController {

    @objc var shouldShowTopJetpackBrandingMenuCard: Bool {
        let presenter = JetpackBrandingMenuCardPresenter(blog: self.blog)
        return presenter.shouldShowTopCard()
    }

    @objc var shouldShowBottomJetpackBrandingMenuCard: Bool {
        let presenter = JetpackBrandingMenuCardPresenter(blog: self.blog)
        return presenter.shouldShowBottomCard()
    }

    @objc func jetpackCardSectionViewModel() -> BlogDetailsSection {
        let row = BlogDetailsRow()
        row.callback = {
            let presenter = JetpackBrandingMenuCardPresenter(blog: self.blog)
            JetpackFeaturesRemovalCoordinator.presentOverlayIfNeeded(in: self, source: .card, blog: self.blog)
            presenter.trackCardTapped()
        }

        let section = BlogDetailsSection(title: nil,
                                         rows: [row],
                                         footerTitle: nil,
                                         category: .jetpackBrandingCard)
        return section
    }

    func reloadTableView() {
        configureTableViewData()
        reloadTableViewPreservingSelection()
    }
}
