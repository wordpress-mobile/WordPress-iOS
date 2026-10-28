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
            self?.meNavigationController.tabBarItem.configureAccountAvatar(avatar)
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
