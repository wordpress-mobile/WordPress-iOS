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
        // The handlers update the tab bar item, and the account notifications
        // can be posted from background threads, so deliver on the main queue.
        let center = NotificationCenter.default
        meTabObservers = [
            center.addObserver(
                forName: .GravatarQEAvatarUpdateNotification,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                self?.refreshAvatar(notification)
            },
            center.addObserver(
                forName: .GravatarImageUpdateNotification,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                self?.updateGravatarImage(notification)
            },
            center.addObserver(
                forName: .wpAccountDefaultWordPressComAccountChanged,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.accountDidChange()
            },
            center.addObserver(
                forName: .WPAccountEmailAndDefaultBlogUpdated,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.accountDidChange()
            }
        ]
    }

    @objc public func configureMeTabImage(placeholderImage: UIImage?) {
        meNavigationController.tabBarItem.image = placeholderImage
        meNavigationController.tabBarItem.selectedImage = nil
        downloadImage()
    }

    func downloadImage(forceRefresh: Bool = false) {
        guard let account = defaultAccount(),
            let email = account.email
        else {
            return
        }

        ImageDownloader.shared.downloadGravatarImage(with: email, forceRefresh: forceRefresh) { [weak self] image in
            guard let image else {
                return
            }

            self?.meNavigationController.tabBarItem.configureGravatarImage(image)
        }
    }

    private func refreshAvatar(_ notification: Foundation.Notification) {
        assert(Thread.isMainThread)
        guard let email = defaultAccount()?.email,
            notification.userInfoHasEmail(email)
        else { return }
        downloadImage(forceRefresh: true)
    }

    private func updateGravatarImage(_ notification: Foundation.Notification) {
        assert(Thread.isMainThread)
        guard let userInfo = notification.userInfo,
            let email = userInfo["email"] as? String,
            let image = userInfo["image"] as? UIImage,
            let url = AvatarURL.url(for: email)
        else {
            return
        }

        ImageCache.shared.setImage(image, forKey: url.absoluteString)
        meNavigationController.tabBarItem.configureGravatarImage(image)
    }

    private func accountDidChange() {
        assert(Thread.isMainThread)
        configureMeTabImage(placeholderImage: UIImage(named: "tab-bar-me"))
    }
}

extension UITabBarItem {

    func configureGravatarImage(_ image: UIImage) {
        let gravatarIcon = image.gravatarIcon(size: 26.0)
        if #available(iOS 26, *) {
            self.image = gravatarIcon
        } else {
            self.image = gravatarIcon?.blackAndWhite?.withAlpha(0.36)
        }
        self.selectedImage = gravatarIcon
    }
}

extension UIImage {

    var blackAndWhite: UIImage? {
        let context = CIContext(options: nil)
        guard let currentFilter = CIFilter(name: "CIPhotoEffectNoir") else { return nil }
        currentFilter.setValue(CIImage(image: self), forKey: kCIInputImageKey)
        if let output = currentFilter.outputImage,
            let cgImage = context.createCGImage(output, from: output.extent)
        {
            return UIImage(cgImage: cgImage, scale: scale, orientation: imageOrientation)
        }
        return nil
    }
}
