import Foundation
import WordPressUI
import Gravatar

extension BlogDetailsViewController {

    @objc func downloadGravatarImage(for row: BlogDetailsRow, forceRefresh: Bool = false) {
        guard let email = blog.account?.email else {
            return
        }

        ImageDownloader.shared.downloadGravatarImage(with: email, forceRefresh: forceRefresh) { [weak self] image in
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
        /*guard let userInfo = notification.userInfo,
            let email = userInfo["email"] as? String,
            let image = userInfo["image"] as? UIImage,
            let url = AvatarURL.url(for: email),
            let gravatarIcon = image.gravatarIcon(size: Metrics.iconSize) else {
                return
        }

        ImageCache.shared.setImage(image, forKey: url.absoluteString)
        meRow?.image = gravatarIcon
        reloadMeRow()*/
        guard let meRow else { return }
        downloadGravatarImage(for: meRow, forceRefresh: true)
    }

    private func reloadMeRow() {
        let meIndexPath = indexPath(for: .me)
        tableView.reloadRows(at: [meIndexPath], with: .automatic)
    }

    private enum Metrics {
        static let iconSize = 24.0
    }
}
