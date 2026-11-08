import Foundation
import WordPressShared
import WordPressUI
import AsyncImageKit
import Gravatar

// MARK: - NoteBlockHeaderTableViewCell
//
class NoteBlockHeaderTableViewCell: NoteBlockTableViewCell {

    // MARK: - Private
    private var authorAvatarURL: URL?
    private typealias Style = WPStyleGuide.Notifications

    // MARK: - Subviews
    private let authorAvatarImageView: UIImageView = {
        let imageView = CircularImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.setContentHuggingPriority(UILayoutPriority(251), for: .horizontal)
        imageView.setContentHuggingPriority(UILayoutPriority(251), for: .vertical)
        return imageView
    }()
    private let headerTitleLabel = NoteBlockHeaderTableViewCell.makeLabel()
    private let headerDetailsLabel = NoteBlockHeaderTableViewCell.makeLabel()

    private lazy var avatarWidthConstraint = authorAvatarImageView.widthAnchor.constraint(equalToConstant: avatarSize)
    private lazy var avatarHeightConstraint: NSLayoutConstraint = {
        let constraint = authorAvatarImageView.heightAnchor.constraint(equalToConstant: avatarSize)
        constraint.priority = UILayoutPriority(999)
        return constraint
    }()

    /// The avatar is larger when both size classes are regular.
    private var avatarSize: CGFloat {
        let isRegular = traitCollection.horizontalSizeClass == .regular && traitCollection.verticalSizeClass == .regular
        return isRegular ? Metrics.regularAvatarSize : Metrics.avatarSize
    }

    // MARK: - Public Properties
    @objc var headerTitle: String? {
        set {
            headerTitleLabel.text = newValue
        }
        get {
            headerTitleLabel.text
        }
    }

    @objc var attributedHeaderTitle: NSAttributedString? {
        set {
            headerTitleLabel.attributedText = newValue
        }
        get {
            headerTitleLabel.attributedText
        }
    }

    @objc var headerDetails: String? {
        set {
            headerDetailsLabel.text = newValue
        }
        get {
            headerDetailsLabel.text
        }
    }

    @objc var attributedHeaderDetails: NSAttributedString? {
        set {
            headerDetailsLabel.attributedText = newValue
        }
        get {
            headerDetailsLabel.attributedText
        }
    }

    // MARK: - Public Methods

    @objc(downloadAuthorAvatarWithURL:)
    func downloadAuthorAvatar(with url: URL?) {
        guard url != authorAvatarURL else {
            return
        }

        authorAvatarURL = url

        guard let url else {
            authorAvatarImageView.image = .gravatarPlaceholderImage
            return
        }
        if let gravatar = AvatarURL(url: url) {
            authorAvatarImageView.downloadGravatar(gravatar, placeholder: .gravatarPlaceholderImage, animate: true)
        } else {
            authorAvatarImageView.wp.setImage(
                with: url,
                size: ImageSize(scaling: SiteIconViewModel.Size.regular.size, in: self)
            )
        }
    }

    // MARK: - View Methods

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setupSubviews()

        accessoryType = .disclosureIndicator
        backgroundColor = Style.blockBackgroundColor

        // No label fonts here: the attributed header title and details carry their own fonts, which
        // depend on the window the cell is displayed in.
        headerTitleLabel.textColor = Style.headerTitleColor
        headerDetailsLabel.textColor = Style.headerDetailsColor
        authorAvatarImageView.image = .gravatarPlaceholderImage
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubviews() {
        headerTitleLabel.heightAnchor.constraint(equalToConstant: Metrics.titleHeight).isActive = true

        let labelsStackView = UIStackView(arrangedSubviews: [headerTitleLabel, headerDetailsLabel])
        labelsStackView.translatesAutoresizingMaskIntoConstraints = false
        labelsStackView.isOpaque = false
        labelsStackView.axis = .vertical

        let stackView = UIStackView(arrangedSubviews: [authorAvatarImageView, labelsStackView])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.isOpaque = false
        stackView.alignment = .center
        stackView.spacing = 8

        contentView.addSubview(stackView)
        contentView.pinSubviewToAllEdgeMargins(stackView)
        NSLayoutConstraint.activate([avatarWidthConstraint, avatarHeightConstraint])

        registerForTraitChanges([UITraitHorizontalSizeClass.self, UITraitVerticalSizeClass.self]) { (self: Self, _) in
            self.avatarWidthConstraint.constant = self.avatarSize
            self.avatarHeightConstraint.constant = self.avatarSize
        }
    }

    private static func makeLabel() -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isOpaque = false
        label.contentMode = .left
        label.font = .systemFont(ofSize: 12)
        label.setContentHuggingPriority(UILayoutPriority(251), for: .horizontal)
        label.setContentHuggingPriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        return label
    }

    // MARK: - Overridden Methods

    override func prepareForReuse() {
        super.prepareForReuse()
        authorAvatarURL = nil
        authorAvatarImageView.cancelImageDownload()
        authorAvatarImageView.image = nil
    }

    override func refreshSeparators() {
        separatorsView.bottomVisible = true
        separatorsView.bottomInsets = fullSeparatorInsets
    }

    private enum Metrics {
        static let avatarSize: CGFloat = 32
        static let regularAvatarSize: CGFloat = 37
        static let titleHeight: CGFloat = 15
    }
}
