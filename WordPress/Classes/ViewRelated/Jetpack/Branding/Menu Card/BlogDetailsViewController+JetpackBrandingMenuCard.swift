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

    func reloadTableView() {
        configureTableViewData()
        reloadTableViewPreservingSelection()
    }
}
