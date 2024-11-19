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
        NotificationCenter.default.addObserver(self, selector: #selector(refreshAvatar(_:)), name: .GravatarQEAvatarUpdateNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateGravatarImage(_:)), name: .GravatarImageUpdateNotification, object: nil)
    }

    @objc private func refreshAvatar(_ notification: Foundation.Notification) {
        guard let meRow,
              let email = blog.account?.email,
              notification.userInfoHasEmail(email) else { return }
        downloadGravatarImage(for: meRow, forceRefresh: true)
    }

    @objc private func updateGravatarImage(_ notification: Foundation.Notification) {
        guard let userInfo = notification.userInfo,
            let email = userInfo["email"] as? String,
            let image = userInfo["image"] as? UIImage,
            let url = AvatarURL.url(for: email),
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
