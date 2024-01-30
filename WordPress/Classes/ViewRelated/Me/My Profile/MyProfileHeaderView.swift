import Foundation
import WordPressUI

class MyProfileHeaderView: UITableViewHeaderFooterView {
    // MARK: - Public Properties and Outlets
    @IBOutlet var gravatarImageView: CircularImageView!
    @IBOutlet var gravatarButton: UIButton!

    // A fake button displayed on top of gravatarImageView.
    let imageViewButton = UIButton(type: .system)

    let activityIndicator = UIActivityIndicatorView(style: .medium)
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
                gravatarImageView.downloadGravatarWithEmail(email, rating: GravatarRatings.x)
            }
        }
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

        configureActivityIndicator()
        configureGravatarImageView()
        configureGravatarButton()
    }

    /// Overrides the current Gravatar Image (set via Email) with a given image reference.
    /// Plus, the internal image cache is updated, to prevent undesired glitches upon refresh.
    ///
    func overrideGravatarImage(_ image: UIImage) {
        gravatarImageView.image = image

        // Note:
        // We need to update the image internal cache. Otherwise, any upcoming query to refresh the gravatar
        // might return the cached (outdated) image, and the UI will end up in an inconsistent state.
        //
        if let email = gravatarEmail {
            gravatarImageView.overrideGravatarImageCache(image, rating: GravatarRatings.x, email: email)
            gravatarImageView.updateGravatar(image: image, email: email)
        }
    }

    private func configureActivityIndicator() {
        activityIndicator.hidesWhenStopped = true
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
    }

    private func configureGravatarImageView() {
        gravatarImageView.shouldRoundCorners = true
        gravatarImageView.addSubview(activityIndicator)
        gravatarImageView.pinSubviewAtCenter(activityIndicator)
        layoutIfNeeded()

        gravatarImageView.addSubview(imageViewButton)
        imageViewButton.translatesAutoresizingMaskIntoConstraints = false
        imageViewButton.pinSubviewToAllEdges(gravatarImageView)
    }

    private func configureGravatarButton() {
        gravatarButton.tintColor = .primary
    }
}
