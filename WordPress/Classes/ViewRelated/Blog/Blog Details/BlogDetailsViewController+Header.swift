import Gridicons

extension BlogDetailsViewController {
    @objc func configureHeaderView() -> NewBlogDetailHeaderView {
        let headerView = NewBlogDetailHeaderView(items: [
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
}

/// A protocol to temporarily share implementations between `BlogDetailHeaderView` and `NewBlogDetailHeaderView`
@objc protocol BlogDetailHeader where Self: UIView {
    var blog: Blog? { get set }
    var updatingIcon: Bool { get set }
    @objc var blavatarImageView: UIImageView { get }
    func refreshIconImage()
}

extension NewBlogDetailHeaderView: BlogDetailHeader {
}

extension BlogDetailHeaderView: BlogDetailHeader {
}
