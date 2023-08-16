import Foundation

extension BlogDetailsViewController {

    @objc func downloadGravatarImage(for row: BlogDetailsRow) {
        guard let email = blog.account?.email else {
            return
        }

        ImageDownloader.shared.downloadGravatarImage(with: email) { [weak self] image in
            guard let image,
                  let gravatarIcon = image.gravatarIcon() else {
                return
            }

            row.image = gravatarIcon
            self?.tableView.reloadData()  // FIXME: only reload Me row
        }
    }

    private func showMe() {
        let controller = MeViewController()
        presentationDelegate?.presentBlogDetailsViewController(controller)
    }
}
