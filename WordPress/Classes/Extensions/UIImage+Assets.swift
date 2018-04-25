import Foundation


// MARK: - WordPress Named Assets
//
extension UIImage {

    /// Returns the Gravatar's "Unapproved" Image.
    ///
    @objc
    static var gravatarUnapprovedImage: UIImage {
        return UIImage(named: "gravatar-unapproved")!
    }
}
