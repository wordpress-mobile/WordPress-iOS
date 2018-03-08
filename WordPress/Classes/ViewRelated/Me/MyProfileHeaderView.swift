import Foundation

class MyProfileHeaderView: WPTableViewCell {
    // MARK: - Public Properties and Outlets
    @IBOutlet var gravatarImageView: CircularImageView!
    @IBOutlet var gravatarButton: UIButton!

    var onAddUpdatePhoto: (() -> Void)?

    class func makeFromNib() -> MyProfileHeaderView {
        return Bundle.main.loadNibNamed("MyProfileHeaderView", owner: self, options: nil)?.first as! MyProfileHeaderView
    }

    // MARK: - Convenience Initializers
    override func awakeFromNib() {
        super.awakeFromNib()

        // Make sure the Outlets are loaded
        assert(gravatarImageView != nil)
        assert(gravatarButton != nil)

        gravatarImageView.shouldRoundCorners = true
    }

    @IBAction func onProfileWasPressed(_ sender: UIButton) {
        onAddUpdatePhoto?()
    }
}
