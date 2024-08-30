import Foundation
import WordPressUI
import Gravatar

extension BlogDetailsViewController {

    @objc func downloadGravatarImage(for row: BlogDetailsRow) {
        guard let email = blog.account?.email else {
            return
        }

        Task { @MainActor [weak self] in
            do {
                let service = Gravatar.AvatarService()
                let result = try await service.fetch(with: .email(email))
                row.image = result.image.gravatarIcon(size: Metrics.iconSize) ?? result.image
                self?.reloadMeRow()
            } catch {
                // Do nothing
            }
        }
    }

    @objc func observeGravatarImageUpdate() {
        NotificationCenter.default.addObserver(self, selector: #selector(updateGravatarImage(_:)), name: .GravatarImageUpdateNotification, object: nil)
    }

    @objc private func updateGravatarImage(_ notification: Foundation.Notification) {
        guard let userInfo = notification.userInfo,
              let image = userInfo["image"] as? UIImage,
              let gravatarIcon = image.gravatarIcon(size: Metrics.iconSize) else {
            return
        }
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
