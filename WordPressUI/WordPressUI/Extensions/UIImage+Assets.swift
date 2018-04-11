import Foundation


// MARK: - Named Assets
//
extension UIImage {

    /// Returns the Default Site Icon Placeholder Image.
    ///
    @objc
    public static var siteIconPlaceholderImage: UIImage {
        return UIImage(named: "blavatar", in: bundle, compatibleWith: nil)!
    }


    /// Returns the Default Gravatar Placeholder Image.
    ///
    @objc
    public static var gravatarPlaceholderImage: UIImage {
        return UIImage(named: "gravatar", in: bundle, compatibleWith: nil)!
    }

    /// Returns WordPressUI's Bundle
    ///
    private static var bundle: Bundle {
        return Bundle(for: UIKitConstants.self)
    }
}
