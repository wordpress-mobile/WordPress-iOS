import Foundation

extension BlogDetailsViewController {

    @objc public var shouldShowTopJetpackBrandingMenuCard: Bool {
        let presenter = JetpackBrandingMenuCardPresenter(blog: self.blog)
        return presenter.shouldShowTopCard()
    }

    func reloadTableView() {
        configureTableViewData()
        reloadTableViewPreservingSelection()
    }
}
