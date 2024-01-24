import Foundation

extension BlogDetailsViewController {

    @objc func downloadGravatarImage(for row: BlogDetailsRow) {
        guard let email = blog.account?.email else {
            return
        }

        ImageDownloader.shared.downloadGravatarImage(with: email) { [weak self] image in
            guard let image,
                  let gravatarIcon = image.gravatarIcon(size: Metrics.iconSize) else {
                return
            }

            row.image = gravatarIcon
            self?.reloadMeRow()
        }
    }

    @objc func observeGravatarImageUpdate() {
        NotificationCenter.default.addObserver(self, selector: #selector(updateGravatarImage(_:)), name: .GravatarImageUpdateNotification, object: nil)
    }

    @objc private func updateGravatarImage(_ notification: Foundation.Notification) {
        guard let userInfo = notification.userInfo,
            let email = userInfo["email"] as? String,
            let image = userInfo["image"] as? UIImage,
            let url = GravatarURL.gravatarUrl(for: email),
            let gravatarIcon = image.gravatarIcon(size: Metrics.iconSize) else {
                return
        }

        ImageCache.shared.setImage(image, forKey: url.absoluteString)
        meRow?.image = gravatarIcon
        reloadMeRow()
    }

    private func reloadMeRow() {
        let meIndexPath = indexPath(for: .me)
        tableView.reloadRows(at: [meIndexPath], with: .automatic)
    }

    private enum Metrics {
        static let iconSize = 24.0
    }
}
