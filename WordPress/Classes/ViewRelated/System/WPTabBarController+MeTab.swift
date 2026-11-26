import Combine
import UIKit

extension WPTabBarController {

    private struct MeTabAssociatedKeys {
        static var accountAvatarSubscription = 0
    }

    /// An Objective-C class extension cannot add stored properties.
    private var meTabAvatarSubscription: AnyCancellable? {
        get {
            objc_getAssociatedObject(self, &MeTabAssociatedKeys.accountAvatarSubscription) as? AnyCancellable
        }
        set {
            objc_setAssociatedObject(
                self,
                &MeTabAssociatedKeys.accountAvatarSubscription,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    /// Shows the account avatar on the Me tab item.
    @objc public func observeAccountAvatar() {
        meTabAvatarSubscription = AccountAvatar.shared.$image.sink { [weak self] avatar in
            guard let self else { return }
            self.performTabBarItemUpdate { [weak self] in
                guard let self, let tab = self.tab(forAppTab: .me) else { return }
                tab.configureAccountAvatar(avatar, isSelected: self.selectedAppTab == .me)
            }
        }
    }

    @objc func updateAccountAvatarForSelection() {
        // Before iOS 26, the inactive Me tab uses a dimmed avatar.
        guard #unavailable(iOS 26) else { return }
        performTabBarItemUpdate { [weak self] in
            guard let self, let tab = self.tab(forAppTab: .me) else { return }
            tab.configureAccountAvatar(AccountAvatar.shared.image, isSelected: self.selectedAppTab == .me)
        }
    }
}

extension UITab {
    func configureAccountAvatar(_ avatar: UIImage?, isSelected: Bool) {
        guard let icon = avatar?.gravatarIcon(size: 26) else {
            image = UIImage(named: "tab-bar-me")
            return
        }
        if #available(iOS 26, *) {
            image = icon
        } else {
            image = isSelected ? icon : icon.blackAndWhite?.withAlpha(0.36)
        }
    }
}

extension UITabBarItem {

    /// Shows `avatar`, or the default Me icon when there is none.
    func configureAccountAvatar(_ avatar: UIImage?) {
        if let avatar {
            configureGravatarImage(avatar)
        } else {
            image = UIImage(named: "tab-bar-me")
            selectedImage = nil
        }
    }

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
            let cgImage = context.createCGImage(output, from: output.extent) {
            return UIImage(cgImage: cgImage, scale: scale, orientation: imageOrientation)
        }
        return nil
    }
}
