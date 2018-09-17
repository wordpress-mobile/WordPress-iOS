import UIKit

protocol EpilogueUserInfoCellViewControllerProvider {
    func viewControllerForEpilogueUserInfoCell() -> UIViewController
}

extension EpilogueUserInfoCellViewControllerProvider where Self: UIViewController {
    func viewControllerForEpilogueUserInfoCell() -> UIViewController {
        guard let navController = navigationController else {
            return self
        }
        return navController
    }
}

// MARK: - EpilogueUserInfoCell
//
class EpilogueUserInfoCell: UITableViewCell {

    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var gravatarView: UIImageView!
    @IBOutlet var gravatarAddIcon: UIImageView!
    @IBOutlet var gravatarActivityIndicator: UIActivityIndicatorView!
    @IBOutlet var fullNameLabel: UILabel!
    @IBOutlet var usernameLabel: UILabel!
    open var viewControllerProvider: EpilogueUserInfoCellViewControllerProvider?
    private var gravatarStatus: GravatarUploaderStatus = .idle
    private var email: String?

    override func awakeFromNib() {
        super.awakeFromNib()
        gravatarView.image = .gravatarPlaceholderImage
    }

    /// Configures the cell so that the LoginEpilogueUserInfo's payload is displayed
    ///
    func configure(userInfo: LoginEpilogueUserInfo, showEmail: Bool = false, allowGravatarUploads: Bool = false) {
        email = userInfo.email

        fullNameLabel.text = userInfo.fullName
        fullNameLabel.fadeInAnimation()

        usernameLabel.text = showEmail ? userInfo.email : "@\(userInfo.username)"
        usernameLabel.fadeInAnimation()

        gravatarAddIcon.isHidden = !allowGravatarUploads

        switch gravatarStatus {
        case .uploading(image: _):
            gravatarActivityIndicator.startAnimating()
        case .finished:
            gravatarActivityIndicator.stopAnimating()
        case .idle:
            let placeholder: UIImage = allowGravatarUploads ? .gravatarUploadablePlaceholderImage : .gravatarPlaceholderImage
            if let gravatarUrl = userInfo.gravatarUrl, let url = URL(string: gravatarUrl) {
                gravatarView.downloadImage(from: url)
            } else {
                gravatarView.downloadGravatarWithEmail(userInfo.email, rating: .x, placeholderImage: placeholder)
            }
        }
    }

    /// Starts the Activity Indicator Animation, and hides the Username + Fullname labels.
    ///
    func startSpinner() {
        fullNameLabel.isHidden = true
        usernameLabel.isHidden = true
        activityIndicator.startAnimating()
    }

    /// Stops the Activity Indicator Animation, and hides the Username + Fullname labels.
    ///
    func stopSpinner() {
        fullNameLabel.isHidden = false
        usernameLabel.isHidden = false
        activityIndicator.stopAnimating()
    }
}

// MARK: - Gravatar uploading
//
extension EpilogueUserInfoCell: GravatarUploader {
    @IBAction func gravatarTapped() {
        guard let vcProvider = viewControllerProvider else {
            return
        }
        let viewController = vcProvider.viewControllerForEpilogueUserInfoCell()
        presentGravatarPicker(from: viewController)
    }

    /// Update the UI based on the status of the gravatar upload
    func updateGravatarStatus(_ status: GravatarUploaderStatus) {
        gravatarStatus = status
        switch status {
        case .uploading(image: let newImage):
            gravatarView.updateGravatar(image: newImage, email: email)
            gravatarActivityIndicator.startAnimating()
        case .idle, .finished:
            gravatarActivityIndicator.stopAnimating()
        }
    }
}

extension UIImage {
    /// Returns a Gravatar Placeholder Image when uploading is allowed
    ///
    fileprivate static var gravatarUploadablePlaceholderImage: UIImage {
        return UIImage(named: "gravatar-hollow", in: nil, compatibleWith: nil)!
    }
}
