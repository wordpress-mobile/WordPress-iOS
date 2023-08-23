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

    @objc func observeGravatarImageUpdate() {
        NotificationCenter.default.addObserver(self, selector: #selector(updateGravatarImage(_:)), name: .GravatarImageUpdateNotification, object: nil)
    }

    @objc private func updateGravatarImage(_ notification: Foundation.Notification) {
        guard let userInfo = notification.userInfo,
            let email = userInfo["email"] as? String,
            let image = userInfo["image"] as? UIImage,
            let url = Gravatar.gravatarUrl(for: email),
            let gravatarIcon = image.gravatarIcon() else {
                return
        }

        ImageCache.shared.setImage(image, forKey: url.absoluteString)
        meRow?.image = gravatarIcon
        tableView.reloadData()  // FIXME: only reload Me row
    }
}
