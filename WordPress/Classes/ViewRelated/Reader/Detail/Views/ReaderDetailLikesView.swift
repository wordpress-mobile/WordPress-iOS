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

    /// Stores the number of total likes _without_ adding the like from self.
    private var totalLikes: Int = 0

    /// Convenience property that adds up the total likes and self like for display purposes.
    var totalLikesForDisplay: Int {
        return displaysSelfAvatar ? totalLikes + 1 : totalLikes
    }

    /// Convenience property that checks whether or not the self avatar image view is being displayed.
    private var displaysSelfAvatar: Bool {
        !selfAvatarImageView.isHidden
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        applyStyles()
    }

    func configure(with avatarURLStrings: [String], totalLikes: Int) {
        self.totalLikes = totalLikes
        updateSummaryLabel()
        updateAvatars(with: avatarURLStrings)
        addTapGesture()
    }

    func addSelfAvatar(with urlString: String, animated: Bool = false) {
        downloadGravatar(for: selfAvatarImageView, withURL: urlString)

        // pre-animation state
        // set initial position from the left in LTR, or from the right in RTL.
        selfAvatarImageView.alpha = 0
        let directionalMultiplier: CGFloat = userInterfaceLayoutDirection() == .leftToRight ? -1.0 : 1.0
        selfAvatarImageView.transform = CGAffineTransform(translationX: Constants.animationDeltaX * directionalMultiplier, y: 0)

        UIView.animate(withDuration: animated ? Constants.animationDuration : 0) {
            // post-animation state
            self.selfAvatarImageView.alpha = 1
            self.selfAvatarImageView.isHidden = false
            self.selfAvatarImageView.transform = .identity
        }

        updateSummaryLabel()
    }

    func removeSelfAvatar(animated: Bool = false) {
        // pre-animation state
        selfAvatarImageView.alpha = 1
        self.selfAvatarImageView.transform = .identity

        UIView.animate(withDuration: animated ? Constants.animationDuration : 0) {
            // post-animation state
            // moves to the left in LTR, or to the right in RTL.
            self.selfAvatarImageView.alpha = 0
            self.selfAvatarImageView.isHidden = true
            let directionalMultiplier: CGFloat = self.userInterfaceLayoutDirection() == .leftToRight ? -1.0 : 1.0
            self.selfAvatarImageView.transform = CGAffineTransform(translationX: Constants.animationDeltaX * directionalMultiplier, y: 0)
        }

        updateSummaryLabel()
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

    func updateSummaryLabel() {
        switch (displaysSelfAvatar, totalLikes) {
        case (true, 0):
            summaryLabel.attributedText = highlightedText(SummaryLabelFormats.onlySelf)
        case (true, 1):
            summaryLabel.attributedText = highlightedText(String(format: SummaryLabelFormats.singularWithSelf, totalLikes))
        case (true, _) where totalLikes > 1:
            summaryLabel.attributedText = highlightedText(String(format: SummaryLabelFormats.pluralWithSelf, totalLikes))
        case (false, 1):
            summaryLabel.attributedText = highlightedText(String(format: SummaryLabelFormats.singular, totalLikes))
        default:
            summaryLabel.attributedText = highlightedText(String(format: SummaryLabelFormats.plural, totalLikes))
        }
    }

    func updateAvatars(with urlStrings: [String]) {
        for (index, subView) in avatarStackView.subviews.enumerated() {
            guard let avatarImageView = subView as? UIImageView else {
                return
            }

            if avatarImageView == selfAvatarImageView {
                continue
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

    struct Constants {
        static let animationDuration: TimeInterval = 0.3
        static let animationDeltaX: CGFloat = 16.0
    }

    struct SummaryLabelFormats {
        static let onlySelf = NSLocalizedString("_You_ like this.",
                                                comment: "Describes that the current user is the only one liking a post."
                                                    + " The underscores denote underline and is not displayed.")
        static let singularWithSelf = NSLocalizedString("_You and %1$d blogger_ like this.",
                                                        comment: "Describes that the current user and one other user like a post."
                                                            + " %1$d is the number of likes, excluding the like by current user."
                                                            + " The underscores denote underline and is not displayed.")
        static let pluralWithSelf = NSLocalizedString("_You and %1$d bloggers_ like this.",
                                                      comment: "Plural format string for displaying the number of post likes, including the like from the current user."
                                                        + " %1$d is the number of likes, excluding the like by current user."
                                                        + " The underscores denote underline and is not displayed.")
        static let singular = NSLocalizedString("_%1$d blogger_ likes this.",
                                                comment: "Describes that only one user likes a post. "
                                                    + " %1$d is the number of likes. The underscores denote underline and is not displayed.")
        static let plural = NSLocalizedString("_%1$d bloggers_ like this.",
                                              comment: "Plural format string for displaying the number of post likes."
                                                + " %1$d is the number of likes. The underscores denote underline and is not displayed.")
    }

    func highlightedText(_ text: String) -> NSAttributedString {
        let labelParts = text.components(separatedBy: "_")

        let firstPart = labelParts.first ?? ""
        let countPart = labelParts[safe: 1] ?? ""
        let lastPart = labelParts.last ?? ""

        let foregroundAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.secondaryLabel]
        let underlineAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.primary,
                                                                  .underlineStyle: NSUnderlineStyle.single.rawValue]

        let attributedString = NSMutableAttributedString(string: firstPart, attributes: foregroundAttributes)
        attributedString.append(NSAttributedString(string: countPart, attributes: underlineAttributes))
        attributedString.append(NSAttributedString(string: lastPart, attributes: foregroundAttributes))

        return attributedString
    }

}
