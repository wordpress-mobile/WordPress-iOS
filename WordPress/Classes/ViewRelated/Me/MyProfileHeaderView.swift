import Foundation

class MyProfileHeaderView: UIView {
    // MARK: - Outlets
    @IBOutlet var gravatarImageView: UIImageView!
    @IBOutlet var gravatarButton: UIButton!

    class func makeFromNib() -> MyProfileHeaderView {
        return Bundle.main.loadNibNamed("MyProfileHeaderView", owner: self, options: nil)?.first as! MyProfileHeaderView
    }

    // MARK: - Convenience Initializers
    override func awakeFromNib() {
        super.awakeFromNib()

        // Make sure the Outlets are loaded
        assert(gravatarImageView != nil)
        assert(gravatarButton != nil)

        gravatarImageView.layer.cornerRadius = CGFloat(gravatarImageView.frame.size.width * 0.5)
    }
}
