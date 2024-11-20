import Foundation
import UIKit

/// Wrapper class used to ensure removeObserver is called
private class GravatarNotificationWrapper {
    let observer: NSObjectProtocol

    init(observer: NSObjectProtocol) {
        self.observer = observer
    }

    deinit {
        NotificationCenter.default.removeObserver(observer)
    }
}

/// UIImageView Helper Methods that allow us to download a Gravatar, given the User's Email
///
extension UIImageView {
    /// Configures the UIImageView to listen for changes to the gravatar it is displaying
    public func listenForGravatarChanges(forEmail trackedEmail: String) {
        if let currentObersver = gravatarWrapper?.observer {
            NotificationCenter.default.removeObserver(currentObersver)
            gravatarWrapper = nil
        }

        let observer = NotificationCenter.default.addObserver(forName: .GravatarImageUpdateNotification, object: nil, queue: nil) { [weak self] (notification) in
            guard let userInfo = notification.userInfo,
                let email = userInfo[Defaults.emailKey] as? String,
                email == trackedEmail,
                let image = userInfo[Defaults.imageKey] as? UIImage else {
                    return
            }

            self?.image = image
        }
        gravatarWrapper = GravatarNotificationWrapper(observer: observer)
    }

    /// Stores the gravatar observer
    ///
    fileprivate var gravatarWrapper: GravatarNotificationWrapper? {
        get {
            return objc_getAssociatedObject(self, &Defaults.gravatarWrapperKey) as? GravatarNotificationWrapper
        }
        set {
            objc_setAssociatedObject(self, &Defaults.gravatarWrapperKey, newValue as AnyObject, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /// Updates the gravatar image for the given email, and notifies all gravatar image views
    ///
    /// - Parameters:
    ///   - image: the new UIImage
    ///   - email: associated email of the new gravatar
    @objc public func updateGravatar(image: UIImage, email: String?) {
        self.image = image
        guard let email else {
            return
        }
        NotificationCenter.default.post(name: .GravatarImageUpdateNotification, object: self, userInfo: [Defaults.emailKey: email, Defaults.imageKey: image])
    }

    // MARK: - Private Helpers

    /// Returns the required gravatar size. If the current view's size is zero, falls back to the default size.
    ///
    private func gravatarDefaultSize() -> Int {
        guard bounds.size.equalTo(.zero) == false else {
            return Defaults.imageSize
        }

        let targetSize = max(bounds.width, bounds.height) * UIScreen.main.scale
        return Int(targetSize)
    }

    /// Private helper structure: contains the default Gravatar parameters
    ///
    private struct Defaults {
        static let imageSize = 80
        static var gravatarWrapperKey = 0x1000
        static let emailKey = "email"
        static let imageKey = "image"
    }
}

public extension NSNotification.Name {
    static let GravatarImageUpdateNotification = NSNotification.Name(rawValue: "GravatarImageUpdateNotification")
}
