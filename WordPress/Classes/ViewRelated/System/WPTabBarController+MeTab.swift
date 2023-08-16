import Foundation

extension WPTabBarController {

    private func defaultAccount() -> WPAccount? {
        try? WPAccount.lookupDefaultWordPressComAccount(in: ContextManager.shared.mainContext)
    }

    @objc func observeGravatarImageUpdate() {
        NotificationCenter.default.addObserver(self, selector: #selector(updateGravatarImage(_:)), name: .GravatarImageUpdateNotification, object: nil)
    }

    @objc func configureMeTabImage(placeholderImage: UIImage) {
        meNavigationController?.tabBarItem.image = placeholderImage

        guard let account = defaultAccount() else {
            return
        }

        ImageDownloader.shared.downloadGravatarImage(with: account.email) { [weak self] image in
            guard let image else {
                return
            }
            self?.meNavigationController?.tabBarItem.updateGravatarImage(image)
        }
    }

    @objc private func updateGravatarImage(_ notification: Foundation.Notification) {
        guard let userInfo = notification.userInfo,
            let image = userInfo["image"] as? UIImage else {
                return
        }

        meNavigationController?.tabBarItem.updateGravatarImage(image)
    }
}

extension NSNotification.Name {
    static let GravatarImageUpdateNotification = NSNotification.Name(rawValue: "GravatarImageUpdateNotification")
}
