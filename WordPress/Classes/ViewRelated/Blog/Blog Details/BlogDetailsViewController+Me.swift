import UIKit
import WordPressUI
import AsyncImageKit
import Gravatar

extension BlogDetailsViewController {

    public func downloadGravatarImage(forceRefresh: Bool = false) {
        guard let email = blog.account?.email else {
            return
        }

        ImageDownloader.shared.downloadGravatarImage(with: email, forceRefresh: forceRefresh) { [weak self] image in
            guard let image,
                  let gravatarIcon = image.gravatarIcon(size: Metrics.iconSize) else {
                return
            }

            self?.tableViewModel?.gravatarIcon = gravatarIcon
        }
    }

    public func observeGravatarImageUpdate() {
        NotificationCenter.default.addObserver(self, selector: #selector(refreshAvatar(_:)), name: .GravatarQEAvatarUpdateNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateGravatarImage(_:)), name: .GravatarImageUpdateNotification, object: nil)
    }

    @objc private func refreshAvatar(_ notification: Foundation.Notification) {
        guard let email = blog.account?.email,
              notification.userInfoHasEmail(email) else { return }
        downloadGravatarImage(forceRefresh: true)
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
        tableViewModel?.gravatarIcon = gravatarIcon
    }

    private enum Metrics {
        static let iconSize = 24.0
    }
}
