import Foundation
import WordPressData
import WordPressUI
import Gravatar
import AsyncImageKit

extension WPTabBarController {

    private func defaultAccount() -> WPAccount? {
        try? WPAccount.lookupDefaultWordPressComAccount(in: ContextManager.shared.mainContext)
    }

    @objc public func observeGravatarImageUpdate() {
        NotificationCenter.default.addObserver(self, selector: #selector(refreshAvatar(_:)), name: .GravatarQEAvatarUpdateNotification, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(updateGravatarImage(_:)), name: .GravatarImageUpdateNotification, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(accountDidChange), name: .wpAccountDefaultWordPressComAccountChanged, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(accountDidChange), name: .WPAccountEmailAndDefaultBlogUpdated, object: nil)
    }

    @objc public func configureMeTabImage(placeholderImage: UIImage?) {
        meNavigationController.tabBarItem.image = placeholderImage
        meNavigationController.tabBarItem.selectedImage = nil
        downloadImage()
    }

    func downloadImage(forceRefresh: Bool = false) {
        guard let account = defaultAccount(),
              let email = account.email else {
            return
        }

        ImageDownloader.shared.downloadGravatarImage(with: email, forceRefresh: forceRefresh) { [weak self] image in
            guard let image else {
                return
            }

            self?.meNavigationController.tabBarItem.configureGravatarImage(image)
        }
    }

    @objc private func refreshAvatar(_ notification: Foundation.Notification) {
        guard let email = defaultAccount()?.email,
              notification.userInfoHasEmail(email) else { return }
        downloadImage(forceRefresh: true)
    }

    @objc private func updateGravatarImage(_ notification: Foundation.Notification) {
        guard let userInfo = notification.userInfo,
            let email = userInfo["email"] as? String,
            let image = userInfo["image"] as? UIImage,
            let url = AvatarURL.url(for: email) else {
                return
        }

        ImageCache.shared.setImage(image, forKey: url.absoluteString)
        meNavigationController.tabBarItem.configureGravatarImage(image)
    }

    @objc private func accountDidChange() {
        configureMeTabImage(placeholderImage: UIImage(named: "tab-bar-me"))
    }
}

extension UITabBarItem {

    func configureGravatarImage(_ image: UIImage) {
        // Pad the 26pt avatar onto the same 32×32 canvas as the other tab bar
        // icons (32×32 vector PDFs). Equal image sizes keep the tab bar layout
        // stable — a differently sized Me icon makes the bar recompute tab
        // widths, truncating and misaligning the titles.
        // See https://github.com/wordpress-mobile/WordPress-iOS/issues/26004
        let canvasSize = CGSize(width: 32, height: 32)
        let gravatarIcon = image.gravatarIcon(size: 26.0)
        if #available(iOS 26, *) {
            self.image = gravatarIcon?.padded(to: canvasSize)
        } else {
            self.image = gravatarIcon?.blackAndWhite?.withAlpha(0.36).padded(to: canvasSize)
        }
        self.selectedImage = gravatarIcon?.padded(to: canvasSize)
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
