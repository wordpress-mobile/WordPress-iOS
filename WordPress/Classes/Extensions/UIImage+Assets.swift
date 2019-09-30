import Foundation


// MARK: - WordPress Named Assets
//
@objc
public extension UIImage {
    /// Returns the Gravatar's "Unapproved" Image.
    ///
    static var gravatarUnapprovedImage: UIImage {
        return UIImage(named: "gravatar-unapproved")!
    }

    static var siteIconPlaceholder: UIImage {
        return UIImage(named: "blavatar-default")!
    }
}
