import UIKit

protocol ReaderDetailLikesViewDelegate {
    func didTapLikesView()
}

class ReaderDetailLikesView: UIView, NibLoadable {

    @IBOutlet weak var avatarStackView: UIStackView!
    @IBOutlet weak var summaryLabel: UILabel!

    /// The UIImageView used to display the current user's avatar image. This view is hidden by default.
    @IBOutlet private weak var selfAvatarImageView: CircularImageView!

    static let maxAvatarsDisplayed = 5
    var delegate: ReaderDetailLikesViewDelegate?

    /// Convenience property that checks whether or not the self avatar image view is being displayed.
    private var displaysSelfAvatar: Bool {
        !selfAvatarImageView.isHidden
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        applyStyles()
    }

    func configure(with avatarURLStrings: [String], totalLikes: Int) {
        updateSummaryLabel(totalLikes: totalLikes)
        updateAvatars(with: avatarURLStrings)
        addTapGesture()
    }

    func addSelfAvatar(with urlString: String) {
        downloadGravatar(for: selfAvatarImageView, withURL: urlString)
        selfAvatarImageView.isHidden = false
    }

    func removeSelfAvatar() {
        selfAvatarImageView.isHidden = true
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
    }

    func updateSummaryLabel(totalLikes: Int) {
        let summaryFormat = totalLikes == 1 ? SummaryLabelFormats.singular : SummaryLabelFormats.plural
        summaryLabel.attributedText = highlightedText(String(format: summaryFormat, totalLikes))
    }

    func updateAvatars(with urlStrings: [String]) {
        for (index, subView) in avatarStackView.subviews.enumerated() {
            guard let avatarImageView = subView as? UIImageView else {
                return
            }

            if let urlString = urlStrings[safe: index] {
                downloadGravatar(for: avatarImageView, withURL: urlString)
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
        static let singular = NSLocalizedString("%1$d blogger_ likes this.",
                                                comment: "Singular format string for displaying the number of post likes. %1$d is the number of likes. The underscore denotes underline and is not displayed.")
        static let plural = NSLocalizedString("%1$d bloggers_ like this.",
                                              comment: "Plural format string for displaying the number of post likes. %1$d is the number of likes. The underscore denotes underline and is not displayed.")
    }

    func highlightedText(_ text: String) -> NSAttributedString {
        let labelParts = text.components(separatedBy: "_")
        let countPart = labelParts.first ?? ""
        let likesPart = labelParts.last ?? ""

        let underlineAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.primary,
                                                                  .underlineStyle: NSUnderlineStyle.single.rawValue]

        let attributedString = NSMutableAttributedString(string: countPart, attributes: underlineAttributes)
        attributedString.append(NSAttributedString(string: likesPart, attributes: [.foregroundColor: UIColor.secondaryLabel]))

        return attributedString
    }

}
