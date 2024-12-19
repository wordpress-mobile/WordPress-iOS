import UIKit

protocol ReaderDetailLikesViewDelegate: AnyObject {
    func didTapLikesView()
}

final class ReaderDetailLikesView: UIView, NibLoadable {
    @IBOutlet private weak var avatarStackView: UIStackView!
    @IBOutlet private weak var summaryLabel: UILabel!
    @IBOutlet private weak var selfAvatarImageView: CircularImageView!

    var displaySetting: ReaderDisplaySetting = .standard {
        didSet {
            applyStyles()
            if let viewModel {
                configure(with: viewModel, animated: false)
            }
        }
    }

    private var preferredBorderColor: UIColor {
        displaySetting.color == .system ? .systemBackground : displaySetting.color.background
    }

    static let maxAvatarsDisplayed = 5

    weak var delegate: ReaderDetailLikesViewDelegate?

    private var viewModel: ReaderDetailLikesViewModel?

    override func awakeFromNib() {
        super.awakeFromNib()

        applyStyles()
        addTapGesture()
    }

    func configure(with viewModel: ReaderDetailLikesViewModel, animated: Bool) {
        self.viewModel = viewModel

        summaryLabel.attributedText = makeHighlightedText(Strings.formattedLikeCount(viewModel.likeCount), displaySetting: displaySetting)

        updateAvatars(with: viewModel.avatarURLs)

        if let avatarURL = viewModel.selfLikeAvatarURL {
            addSelfAvatar(with: avatarURL, animated: animated)
        } else {
            removeSelfAvatar(animated: animated)
        }
    }

    private func addSelfAvatar(with urlString: String, animated: Bool = false) {
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
    }

    private func removeSelfAvatar(animated: Bool = false) {
        // pre-animation state
        selfAvatarImageView.alpha = 1
        selfAvatarImageView.transform = .identity

        UIView.animate(withDuration: animated ? Constants.animationDuration : 0) {
            // post-animation state
            // moves to the left in LTR, or to the right in RTL.
            self.selfAvatarImageView.alpha = 0
            self.selfAvatarImageView.isHidden = true
            let directionalMultiplier: CGFloat = self.userInterfaceLayoutDirection() == .leftToRight ? -1.0 : 1.0
            self.selfAvatarImageView.transform = CGAffineTransform(translationX: Constants.animationDeltaX * directionalMultiplier, y: 0)
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        applyStyles()
    }
}

private extension ReaderDetailLikesView {
    @MainActor
    func applyStyles() {
        for subView in avatarStackView.subviews {
            subView.layer.borderWidth = 1
            subView.layer.borderColor = preferredBorderColor.cgColor
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
        avatarImageView.wp.prepareForReuse()
        avatarImageView.image = .gravatarPlaceholderImage
        if let url, let gravatarURL = URL(string: url) {
            avatarImageView.wp.setImage(with: gravatarURL)
        }
    }

    func addTapGesture() {
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapView)))
    }

    @objc func didTapView(_ gesture: UITapGestureRecognizer) {
        delegate?.didTapLikesView()
    }

    struct Constants {
        static let animationDuration: TimeInterval = 0.3
        static let animationDeltaX: CGFloat = 16.0
    }
}

private func makeHighlightedText(_ text: String, displaySetting: ReaderDisplaySetting) -> NSAttributedString {
    let labelParts = text.components(separatedBy: "_")

    let firstPart = labelParts.first ?? ""
    let countPart = labelParts[safe: 1] ?? ""
    let lastPart = labelParts.last ?? ""

    let foregroundColor = displaySetting.color.secondaryForeground
    let highlightedColor = displaySetting.color == .system ? UIAppColor.primary : displaySetting.color.foreground

    let foregroundAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: foregroundColor]
    var highlightedAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: highlightedColor]

    if displaySetting.color != .system {
        // apply underline and semibold weight for color themes other than `.system`.
        highlightedAttributes[.font] = displaySetting.font(with: .footnote, weight: .semibold)
        highlightedAttributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
    }

    let attributedString = NSMutableAttributedString(string: firstPart, attributes: foregroundAttributes)
    attributedString.append(NSAttributedString(string: countPart, attributes: highlightedAttributes))
    attributedString.append(NSAttributedString(string: lastPart, attributes: foregroundAttributes))

    return attributedString
}

struct ReaderDetailLikesViewModel {
    /// A total like count, including your likes.
    let likeCount: Int
    /// Avatar URLs excluding self-like view.
    let avatarURLs: [String]
    let selfLikeAvatarURL: String?
}

private enum Strings {
    static let likeCountSingular = NSLocalizedString("reader.detail.likes.single", value: "_1 like_", comment: "Describes that only one user likes a post. The underscores denote underline and is not displayed.")
    static let likeCountPlural = NSLocalizedString("reader.detail.likes.plural", value: "_%1$d likes_", comment: "Plural format string for displaying the number of post likes. %1$d is the number of likes. The underscores denote underline and is not displayed.")

    static func formattedLikeCount(_ likeCount: Int) -> String {
        switch likeCount {
        case 1: Strings.likeCountSingular
        default: String(format: Strings.likeCountPlural, likeCount)
        }
    }
}
