import Foundation

extension WPTabBarController {

    private func defaultAccount() -> WPAccount? {
        try? WPAccount.lookupDefaultWordPressComAccount(in: ContextManager.shared.mainContext)
    }

    @objc func observeGravatarImageUpdate() {
        NotificationCenter.default.addObserver(self, selector: #selector(updateGravatarImage(_:)), name: .GravatarImageUpdateNotification, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(accountDidChange), name: .WPAccountDefaultWordPressComAccountChanged, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(accountDidChange), name: .WPAccountEmailAndDefaultBlogUpdated, object: nil)
    }

    @objc func configureMeTabImage(placeholderImage: UIImage?) {
        configureMeTabImage(unselectedPlaceholderImage: placeholderImage, selectedPlaceholderImage: placeholderImage)
    }

    @objc func configureMeTabImage(unselectedPlaceholderImage: UIImage?, selectedPlaceholderImage: UIImage?) {
        meNavigationController?.tabBarItem.image = unselectedPlaceholderImage
        meNavigationController?.tabBarItem.selectedImage = selectedPlaceholderImage

        guard let account = defaultAccount(),
              let email = account.email else {
            return
        }

        ImageDownloader.shared.downloadGravatarImage(with: email) { [weak self] image in
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

    @objc private func accountDidChange() {
        guard FeatureFlag.newTabIcons.enabled else {
            configureMeTabImage(placeholderImage: UIImage(named: "icon-tab-me"))
            return
        }

        configureMeTabImage(unselectedPlaceholderImage: UIImage(named: "tab-bar-me-unselected"),
                            selectedPlaceholderImage: UIImage(named: "tab-bar-me-selected"))
    }
}

extension UITabBarItem {

    func configureGravatarImage(_ image: UIImage) {
        let gravatarIcon = image.gravatarIcon(size: 26.0)
        self.image = gravatarIcon?.blackAndWhite?.withAlpha(0.36)
        self.selectedImage = gravatarIcon
    }
}

extension UIImage {

    var blackAndWhite: UIImage? {
        let context = CIContext(options: nil)
        guard let currentFilter = CIFilter(name: "CIPhotoEffectNoir") else { return nil }
        currentFilter.setValue(CIImage(image: self), forKey: kCIInputImageKey)
        if let output = currentFilter.outputImage,
            let cgImage = context.createCGImage(output, from: output.extent) {
            return UIImage(cgImage: cgImage, scale: scale, orientation: imageOrientation)
        }
        return nil
    }
}
