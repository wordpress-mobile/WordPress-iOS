import UIKit

protocol ReaderDetailLikesViewDelegate {
    func didTapLikesView()
}

class ReaderDetailLikesView: UIView, NibLoadable {

    @IBOutlet weak var avatarStackView: UIStackView!
    @IBOutlet weak var summaryLabel: UILabel!

    static let maxAvatarsDisplayed = 5
    var delegate: ReaderDetailLikesViewDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        applyStyles()
    }

    func configure(users: [LikeUser], totalLikes: Int) {
        updateSummaryLabel(totalLikes: totalLikes)
        updateAvatars(users: users)
        addTapGesture()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        applyStyles()
    }

}

private extension ReaderDetailLikesView {

    func applyStyles() {
        // Set border on all the avatar views
        for subView in avatarStackView.subviews {
            subView.layer.borderWidth = 1
            subView.layer.borderColor = UIColor.basicBackground.cgColor
        }

        summaryLabel.textColor = .secondaryLabel
    }

    func updateSummaryLabel(totalLikes: Int) {
        let summaryFormat = totalLikes == 1 ? SummaryLabelFormats.singular : SummaryLabelFormats.plural
        summaryLabel.text = String(format: summaryFormat, totalLikes)
    }

    func updateAvatars(users: [LikeUser]) {
        for (index, subView) in avatarStackView.subviews.enumerated() {
            guard let avatarImageView = subView as? UIImageView else {
                return
            }

            if let user = users[safe: index] {
                downloadGravatar(for: avatarImageView, withURL: user.avatarUrl)
            } else {
                avatarImageView.isHidden = true
            }
        }
    }

    func downloadGravatar(for avatarImageView: UIImageView, withURL url: String?) {
        // Always reset gravatar
        avatarImageView.cancelImageDownload()
        avatarImageView.image = .gravatarPlaceholderImage

        guard let url = url,
              let gravatarURL = URL(string: url) else {
            return
        }

        avatarImageView.downloadImage(from: gravatarURL, placeholderImage: .gravatarPlaceholderImage)
    }

    func addTapGesture() {
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapView(_:))))
    }

    @objc func didTapView(_ gesture: UITapGestureRecognizer) {
        guard gesture.state == .ended else {
            return
        }

        delegate?.didTapLikesView()
    }

    struct SummaryLabelFormats {
        static let singular = NSLocalizedString("%1$d blogger likes this.",
                                                comment: "Singular format string for displaying the number of post likes. %1$d is the number of likes.")
        static let plural = NSLocalizedString("%1$d bloggers like this.",
                                              comment: "Plural format string for displaying the number of post likes. %1$d is the number of likes.")
    }

}
