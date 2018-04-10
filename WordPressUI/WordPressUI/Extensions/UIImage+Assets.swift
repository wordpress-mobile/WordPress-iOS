import Foundation


// MARK: - Named Assets
//
extension UIImage {

    /// Returns the Default Blavatar Placeholder Image.
    ///
    @objc
    public static var blavatarPlaceholderImage: UIImage {
        return UIImage(named: "blavatar")!
    }


    /// Returns the Default Gravatar Placeholder Image.
    ///
    @objc
    public static var gravatarPlaceholderImage: UIImage {
        return UIImage(named: "gravatar")!
    }
}
