import UIKit

class LoginEpilogueBlogCell: WPBlogTableViewCell {
    @IBOutlet var siteNameLabel: UILabel?
    @IBOutlet var urlLabel: UILabel?
    @IBOutlet var siteIcon: UIImageView?
    @IBOutlet var siteNameVerticalConstraint: NSLayoutConstraint!

    override var textLabel: UILabel? {
        get {
            return siteNameLabel
        }
    }

    override var detailTextLabel: UILabel? {
        get {
            return urlLabel
        }
    }

    override var imageView: UIImageView? {
        get {
            return siteIcon
        }
    }

    func adjustSiteNameConstraint() {
        // If the URL is nil, center the Site Name vertically with the site icon.
        siteNameVerticalConstraint.isActive = (urlLabel?.text == nil)
    }

}
