import Foundation
import WordPressUI

class MyProfileHeaderView: UITableViewHeaderFooterView {
    // MARK: - Public Properties and Outlets
    @IBOutlet var gravatarImageView: CircularImageView!
    @IBOutlet var gravatarButton: UIButton!
    weak var presentingViewController: UIViewController?
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
            if gravatarEmail != nil {
                downloadAvatar()
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

    private func downloadAvatar(forceRefresh: Bool = false) {
        if let email = gravatarEmail {
            gravatarImageView.downloadGravatar(for: email, gravatarRating: .x, forceRefresh: forceRefresh)
        }
    }

    @objc private func refreshAvatar(_ notification: Foundation.Notification) {
        guard let email = gravatarEmail,
              notification.userInfoHasEmail(email) else { return }
        downloadAvatar(forceRefresh: true)
    }

    /// Overrides the current Gravatar Image (set via Email) with a given image reference.
    /// Plus, the internal image cache is updated, to prevent undesired glitches upon refresh.
    ///
    func overrideGravatarImage(_ image: UIImage) {
        guard !RemoteFeatureFlag.gravatarQuickEditor.enabled() else { return }
        gravatarImageView.image = image

        // Note:
        // We need to update the image internal cache. Otherwise, any upcoming query to refresh the gravatar
        // might return the cached (outdated) image, and the UI will end up in an inconsistent state.
        //
        if let email = gravatarEmail {
            gravatarImageView.overrideGravatarImageCache(image, gravatarRating: ObjcGravatarRating.x, email: email)
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
        if RemoteFeatureFlag.gravatarQuickEditor.enabled() {
            imageViewButton.addTarget(self, action: #selector(gravatarButtonTapped), for: .touchUpInside)
            NotificationCenter.default.addObserver(self, selector: #selector(refreshAvatar), name: .GravatarQEAvatarUpdateNotification, object: nil)
        }
    }

    private func configureGravatarButton() {
        gravatarButton.tintColor = UIAppColor.primary
        if RemoteFeatureFlag.gravatarQuickEditor.enabled() {
            gravatarButton.addTarget(self, action: #selector(gravatarButtonTapped), for: .touchUpInside)
        }
    }

    @objc private func gravatarButtonTapped() {
        guard let email = gravatarEmail,
              let presenter = GravatarQuickEditorPresenter(email: email),
              let presentingViewController else { return }
        presenter.presentQuickEditor(on: presentingViewController)
    }
}
