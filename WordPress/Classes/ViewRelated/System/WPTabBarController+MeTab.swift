import Foundation
import WordPressUI
import Gravatar

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
        meNavigationController?.tabBarItem.image = placeholderImage

        guard let account = defaultAccount(),
              let email = account.email else {
            return
        }

        Task { @MainActor [weak self] in
            do {
                let image = try await GravatarImageService.shared.image(for: email)
                self?.meNavigationController?.tabBarItem.configureGravatarImage(image)
            } catch {
                // Do nothing
            }
        }
    }

    @objc private func updateGravatarImage(_ notification: Foundation.Notification) {
        guard let userInfo = notification.userInfo,
              let image = notification.userInfo?["image"] as? UIImage else {
            return
        }
        meNavigationController?.tabBarItem.configureGravatarImage(image)
    }

    @objc private func accountDidChange() {
        configureMeTabImage(placeholderImage: UIImage(named: "tab-bar-me"))
    }
}

extension UITabBarItem {

    func configureGravatarImage(_ image: UIImage) {
        let gravatarIcon = image.gravatarIcon(size: 26.0)
        self.image = gravatarIcon.blackAndWhite?.withAlpha(0.36)
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
