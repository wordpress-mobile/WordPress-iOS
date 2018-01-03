import Foundation


// MARK: - WordPress Named Assets
//
extension UIImage {

    /// Returns the Default SiteIcon Placeholder Image.
    ///
    @objc
    static var siteIconPlaceholderImage: UIImage {
        return UIImage(named: "blavatar-default")!
    }


    /// Returns the Default Gravatar Placeholder Image.
    ///
    @objc
    static var gravatarPlaceholderImage: UIImage {
        return UIImage(named: "gravatar.png")!
    }


    /// Returns the Gravatar's "Unapproved" Image.
    ///
    @objc
    static var gravatarUnapprovedImage: UIImage {
        return UIImage(named: "gravatar-unapproved")!
    }
}
