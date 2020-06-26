import Gridicons

extension BlogDetailsViewController {
    @objc func configureHeaderView() -> BlogDetailHeaderView {
        let headerView = BlogDetailHeaderView(items: [
            ActionRow.Item(image: .gridicon(.statsAlt), title: NSLocalizedString("Stats", comment: "Noun. Abbv. of Statistics. Links to a blog's Stats screen.")) { [weak self] in
                self?.tableView.deselectSelectedRowWithAnimation(false)
                self?.showStats(from: .button)
            },
            ActionRow.Item(image: .gridicon(.pages), title: NSLocalizedString("Pages", comment: "Noun. Title. Links to the blog's Pages screen.")) { [weak self] in
                self?.tableView.deselectSelectedRowWithAnimation(false)
                self?.showPageList(from: .button)
            },
            ActionRow.Item(image: .gridicon(.posts), title: NSLocalizedString("Posts", comment: "Noun. Title. Links to the blog's Posts screen.")) { [weak self] in
                self?.tableView.deselectSelectedRowWithAnimation(false)
                self?.showPostList(from: .button)
            },
            ActionRow.Item(image: .gridicon(.image), title: NSLocalizedString("Media", comment: "Noun. Title. Links to the blog's Media library.")) { [weak self] in
                self?.tableView.deselectSelectedRowWithAnimation(false)
                self?.showMediaLibrary(from: .button)
            }
        ])
        return headerView
    }

    @objc func blogDetailHeaderViewTitleTapped() {
        let controller = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        let title = NSLocalizedString("Change site title", comment: "Menu option allowing the user to change their site's title")
        controller.addAction(UIAlertAction(title: title, style: .default, handler: { [weak self] action in
            self?.showSettingsHighlighting(IndexPath(row: 0, section: 0))
        }))
        controller.addCancelActionWithTitle(NSLocalizedString("Cancel", comment: "Cancels out of a menu"))

        present(controller, animated: true)
    }
}
