import Foundation


// MARK: - Named Assets
//
extension UIImage {

    /// Returns the Default Site Icon Placeholder Image.
    ///
    @objc
    public static var siteIconPlaceholderImage: UIImage {
        return UIImage(named: "blavatar")!
    }


    /// Returns the Default Gravatar Placeholder Image.
    ///
    @objc
    public static var gravatarPlaceholderImage: UIImage {
        return UIImage(named: "gravatar")!
    }
}
