import Foundation

@objc public extension UserSuggestion {
    func cachedAvatar(with size: CGSize) -> UIImage? {
        var hash: NSString?
        let type = avatarSourceType(with: &hash)

        if let hash = hash, let type = type {
            return WPAvatarSource.shared()?.cachedImage(forAvatarHash: hash as String, of: type, with: size)
        }
        return nil
    }

    func fetchAvatar(with size: CGSize, success: ((UIImage?) -> Void)?) {
        var hash: NSString?
        let type = avatarSourceType(with: &hash)

        if let hash = hash, let type = type, let success = success {
            WPAvatarSource.shared()?.fetchImage(forAvatarHash: hash as String, of: type, with: size, success: success)
        } else {
            success?(nil)
        }
    }
}

extension UserSuggestion {
    func avatarSourceType(with hash: inout NSString?) -> WPAvatarSourceType? {
        if let imageURL = imageURL {
            return WPAvatarSource.shared()?.parseURL(imageURL, forAvatarHash: &hash)
        }
        return .unknown
    }
}
