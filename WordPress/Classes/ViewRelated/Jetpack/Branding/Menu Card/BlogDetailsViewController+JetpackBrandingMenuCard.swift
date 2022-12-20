import Foundation

extension BlogDetailsViewController {

    @objc var shouldShowJetpackBrandingMenuCard: Bool {
        let presenter = JetpackBrandingMenuCardPresenter()
        return presenter.shouldShowCard()
    }

    @objc func jetpackCardSectionViewModel() -> BlogDetailsSection {
        let row = BlogDetailsRow()
        row.callback = {
            JetpackFeaturesRemovalCoordinator.presentOverlayIfNeeded(from: .card, in: self)
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
