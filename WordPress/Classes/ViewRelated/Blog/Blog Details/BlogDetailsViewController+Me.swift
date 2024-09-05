import Foundation
import WordPressUI
import Gravatar

extension BlogDetailsViewController {

    @objc func downloadGravatarImage(for row: BlogDetailsRow) {
        guard let email = blog.account?.email else {
            return
        }
        let service = GravatarImageService.shared
        if let image = service.cacheImage(for: email) {
            row.image = image.gravatarIcon(size: Metrics.iconSize)
            reloadMeRow()
        } else {
            Task { @MainActor [weak self] in
                do {
                    let image = try await service.image(for: email)
                    row.image = image.gravatarIcon(size: Metrics.iconSize)
                    self?.reloadMeRow()
                } catch {
                    // Do nothing
                }
            }
        }
    }

    @objc func observeGravatarImageUpdate() {
        NotificationCenter.default.addObserver(self, selector: #selector(updateGravatarImage), name: .GravatarImageUpdateNotification, object: nil)
    }

    @objc private func updateGravatarImage(_ notification: Foundation.Notification) {
        guard let userInfo = notification.userInfo,
              let image = userInfo["image"] as? UIImage else {
            return
        }
        meRow?.image = image.gravatarIcon(size: Metrics.iconSize)
        reloadMeRow()
    }

    private func reloadMeRow() {
        tableView.reloadRows(at: [indexPath(for: .me)], with: .automatic)
    }

    private enum Metrics {
        static let iconSize = 24.0
    }
}
