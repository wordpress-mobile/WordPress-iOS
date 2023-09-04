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

            self?.meNavigationController?.tabBarItem.configureGravatarImage(image)
        }
    }

    @objc private func updateGravatarImage(_ notification: Foundation.Notification) {
        guard let userInfo = notification.userInfo,
            let email = userInfo["email"] as? String,
            let image = userInfo["image"] as? UIImage,
            let url = Gravatar.gravatarUrl(for: email) else {
                return
        }

        ImageCache.shared.setImage(image, forKey: url.absoluteString)
        meNavigationController?.tabBarItem.configureGravatarImage(image)
    }
}

extension UITabBarItem {

    func configureGravatarImage(_ image: UIImage) {
        let gravatarIcon = image.gravatarIcon(size: 28.0)
        self.image = gravatarIcon?.withAlpha(0.36)
        self.selectedImage = gravatarIcon
    }
}
