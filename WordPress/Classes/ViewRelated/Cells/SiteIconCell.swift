import Foundation
import UIKit

@objc class SiteIconCell: WPTableViewCell {
    // MARK: - Public Properties and Outlets
    @objc @IBOutlet var blavatarImageView: UIImageView!
    @objc @IBOutlet var blavatarButton: UIButton!

    @objc static let defaultReuseIdentifier = "SiteIconCell"

    @objc static let nib: UINib = {
        let nib = UINib(nibName: "SiteIconCell", bundle: Bundle(for: SiteIconCell.self))
        return nib
    }()

    @objc var onAddUpdateIcon: (() -> Void)?
    @objc var onRefreshIconImage: (() -> Void)?
    @objc var activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .white)
    @objc var showsActivityIndicator: Bool {
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

    // MARK: - Convenience Initializers
    override func awakeFromNib() {
        super.awakeFromNib()

        // Make sure the Outlets are loaded
        assert(blavatarImageView != nil)
        assert(blavatarButton != nil)

        configureActivityIndicator()
        configureBlavatarImageView()
    }

    @objc @IBAction func onBlavatarWasPressed(_ sender: UIButton) {
        onAddUpdateIcon?()
    }

    @objc func configureActivityIndicator() {
        activityIndicator.hidesWhenStopped = true
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
    }

    @objc func configureBlavatarImageView() {
        blavatarImageView.addSubview(activityIndicator)
        blavatarImageView.pinSubviewAtCenter(activityIndicator)
        setNeedsUpdateConstraints()

        let recognizer = UITapGestureRecognizer(target: self, action: #selector(onBlavatarWasPressed(_:)))
        blavatarImageView.addGestureRecognizer(recognizer)
    }
}
