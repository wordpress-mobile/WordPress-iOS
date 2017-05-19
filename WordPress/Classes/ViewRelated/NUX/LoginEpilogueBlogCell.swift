import UIKit

class LoginEpilogueBlogCell: WPBlogTableViewCell {
    @IBOutlet var siteNameLabel: UILabel?
    @IBOutlet var urlLabel: UILabel?
    @IBOutlet var siteIcon: UIImageView?

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
}
