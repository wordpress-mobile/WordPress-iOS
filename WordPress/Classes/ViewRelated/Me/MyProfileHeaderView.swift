import Foundation

class MyProfileHeaderView: WPTableViewCell {
    // MARK: - Public Properties and Outlets
    @IBOutlet var gravatarImageView: CircularImageView!
    @IBOutlet var gravatarButton: UIButton!

    var onAddUpdatePhoto: (() -> Void)?
    var activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .white)
    var showsActivityIndicator: Bool {
        get {
            return activityIndicator.isAnimating
        }
        set {
            if newValue == true {
                activityIndicator.startAnimating()
            } else {
                activityIndicator.stopAnimating()
            }
        }
    }
    var gravatarEmail: String? = nil {
        didSet {
            if let email = gravatarEmail {
                gravatarImageView.downloadGravatarWithEmail(email, rating: UIImageView.GravatarRatings.x)
            }
        }
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

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
        contentView.insertSubview(activityIndicator, aboveSubview: gravatarImageView)
        gravatarImageView.pinSubviewToAllEdges(activityIndicator)
    }

    @IBAction func onProfileWasPressed(_ sender: UIButton) {
        onAddUpdatePhoto?()
    }

    /// Overrides the current Gravatar Image (set via Email) with a given image reference.
    /// Plus, AFNetworking's internal cache is updated, to prevent undesired glitches upon refresh.
    ///
    func overrideGravatarImage(_ image: UIImage) {
        gravatarImageView.image = image

        // Note:
        // We need to update AFNetworking's internal cache. Otherwise, any upcoming query to refresh the gravatar
        // might return the cached (outdated) image, and the UI will end up in an inconsistent state.
        //
        if let email = gravatarEmail {
            gravatarImageView.overrideGravatarImageCache(image, rating: UIImageView.GravatarRatings.x, email: email)
        }
    }
}
