import Foundation
import AutomatticTracks
import WordPressUI

final class ReaderCrossPostCell: ReaderStreamBaseCell {
    private let view = ReaderCrossPostView()
    private var contentViewConstraints: [NSLayoutConstraint] = []

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: contentView.topAnchor),
            view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).withPriority(999),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        view.prepareForReuse()
    }

    func configure(with post: ReaderPost) {
        view.configure(with: post)
    }

    override func didUpdateCompact(_ isCompact: Bool) {
        setNeedsUpdateConstraints()
    }

    override func updateConstraints() {
        NSLayoutConstraint.deactivate(contentViewConstraints)
        contentViewConstraints = view.pinEdges(.horizontal, to: isCompact ? contentView : contentView.readableContentGuide)
        super.updateConstraints()
    }
}

private final class ReaderCrossPostView: UIView {
    private let avatarView = ReaderAvatarView()
    private let iconView = ReaderAvatarView()
    private let headerLabel = UILabel()
    private let postTitleLabel = UILabel()

    private let insets = ReaderStreamBaseCell.insets
    private let avatarSize: CGFloat = 28
    private let crossPostIconSize: CGFloat = 18

    private let postTitleAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.preferredFont(forTextStyle: .subheadline).semibold(),
        .foregroundColor: UIColor.label
    ]

    private let subtitleAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.preferredFont(forTextStyle: .footnote),
        .foregroundColor: UIColor.secondaryLabel
    ]

    private let boldSubtitleAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.preferredFont(forTextStyle: .footnote).semibold(),
        .foregroundColor: UIColor.secondaryLabel
    ]

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupStyle()
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }

    func prepareForReuse() {
        avatarView.prepareForReuse()
    }

    // MARK: Setup

    private func setupStyle() {
        headerLabel.numberOfLines = 2
        headerLabel.adjustsFontForContentSizeCategory = true
        headerLabel.maximumContentSizeCategory = .accessibilityExtraLarge

        postTitleLabel.numberOfLines = 2
        postTitleLabel.adjustsFontForContentSizeCategory = true
        postTitleLabel.maximumContentSizeCategory = .accessibilityExtraLarge

        iconView.setStaticIcon(crossPostIcon, tintColor: .secondaryLabel)
    }

    private func setupLayout() {
        for view in [avatarView, iconView, headerLabel, postTitleLabel] {
            addSubview(view)
            view.translatesAutoresizingMaskIntoConstraints = false
        }
        NSLayoutConstraint.activate([
            avatarView.widthAnchor.constraint(equalToConstant: avatarSize),
            avatarView.heightAnchor.constraint(equalToConstant: avatarSize),
            avatarView.centerYAnchor.constraint(equalTo: headerLabel.centerYAnchor),
            avatarView.trailingAnchor.constraint(equalTo: headerLabel.leadingAnchor, constant: -8),

            iconView.widthAnchor.constraint(equalToConstant: crossPostIconSize),
            iconView.heightAnchor.constraint(equalToConstant: crossPostIconSize),
            iconView.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor, constant: crossPostIconSize / 2 - 1),
            iconView.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor, constant: crossPostIconSize / 2 + 3),

            headerLabel.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            headerLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: insets.left),
            headerLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),

            postTitleLabel.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 6),
            postTitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: insets.left),
            postTitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -insets.right),
            postTitleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
        ])
    }

    // MARK: Configuration

    func configure(with post: ReaderPost) {
        headerLabel.attributedText = makeHeaderString(for: post)
        postTitleLabel.attributedText = NSAttributedString(string: post.titleForDisplay() ?? "", attributes: postTitleAttributes)

        avatarView.setPlaceholder(UIImage(named: "post-blavatar-placeholder"))
        if let avatarURL = post.avatarURLForDisplay() {
            let avatarSize = ImageSize(scaling: CGSize(width: avatarSize, height: avatarSize), in: self)
            avatarView.setImage(with: avatarURL, size: avatarSize)
        }
    }

    private func makeHeaderString(for post: ReaderPost) -> NSAttributedString? {
        guard let meta = post.crossPostMeta else {
            return nil
        }
        let template = meta.commentURL.isEmpty ? Strings.siteTemplate : Strings.commentTemplate

        let authorName: NSString = post.authorForDisplay() as NSString
        let siteName = subdomainNameFromPath(post.blogURL)
        let originName = subdomainNameFromPath(meta.siteURL)

        let subtitle = NSString(format: template as NSString, authorName, originName, siteName) as String
        let string = NSMutableAttributedString(string: subtitle, attributes: subtitleAttributes)

        string.setAttributes(boldSubtitleAttributes, range: NSRange(location: 0, length: authorName.length))
        if let siteRange = subtitle.nsRange(of: siteName) {
            string.setAttributes(boldSubtitleAttributes, range: siteRange)
        }
        if let originRange = subtitle.nsRange(of: originName) {
            string.setAttributes(boldSubtitleAttributes, range: originRange)
        }
        return string
    }
}

private func subdomainNameFromPath(_ path: String) -> String {
    guard let url = URL(string: path), let host = url.host else {
        return ""
    }
    return host.components(separatedBy: ".").first ?? ""
}

private let crossPostIcon = UIImage(named: "wpl-shuffle")?
    .resized(to: CGSize(width: 16, height: 16))
    .withRenderingMode(.alwaysTemplate)

private struct Strings {
    // TODO: add localization but make sure to update ranges in makeHeaderString!
    static let commentTemplate = "%1$@ left a comment on %2$@, cross-posted to %3$@"
    static let siteTemplate = "%1$@ cross-posted from %2$@ to %3$@"
}
