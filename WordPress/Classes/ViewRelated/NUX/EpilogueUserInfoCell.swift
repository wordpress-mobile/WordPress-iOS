import UIKit

// MARK: - EpilogueUserInfoCell
//
class EpilogueUserInfoCell: UITableViewCell {

    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var gravatarView: UIImageView!
    @IBOutlet var gravatarActivityIndicator: UIActivityIndicatorView!
    @IBOutlet var fullNameLabel: UILabel!
    @IBOutlet var usernameLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        gravatarView.image = .gravatarPlaceholderImage
    }

    /// Configures the cell so that the LoginEpilogueUserInfo's payload is displayed
    ///
    func configure(userInfo: LoginEpilogueUserInfo, showEmail: Bool = false) {
        fullNameLabel.text = userInfo.fullName
        fullNameLabel.fadeInAnimation()

        usernameLabel.text = showEmail ? userInfo.email : "@\(userInfo.username)"
        usernameLabel.fadeInAnimation()

        if let gravatarUrl = userInfo.gravatarUrl, let url = URL(string: gravatarUrl) {
            gravatarView.downloadImage(from: url)
        } else {
            gravatarView.downloadGravatarWithEmail(userInfo.email, rating: .x)
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

    var parentViewController: UIViewController? {
        var parentResponder: UIResponder? = self
        while parentResponder != nil {
            parentResponder = parentResponder!.next
            if let viewController = parentResponder as? UIViewController {
                return viewController
            }
        }
        return nil
    }

    @IBAction func gravatarTapped() {
        presentGravatarPicker(from: parentViewController!)
    }
}

extension EpilogueUserInfoCell: GravatarUploader {
    func updateGravatarStatus(_ status: GravatarUploaderStatus) {
        switch status {
        case .uploading(image: let newImage):
            gravatarView.image = newImage
            gravatarActivityIndicator.startAnimating()
        case .idle, .finished:
            gravatarActivityIndicator.stopAnimating()
        }
    }
}
