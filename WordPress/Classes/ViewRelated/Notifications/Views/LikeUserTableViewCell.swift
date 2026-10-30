import Foundation
import FormattableContentKit
import WordPressData
import WordPressShared
import WordPressUI

class LikeUserTableViewCell: UITableViewCell, Reusable {

    // MARK: - Properties

    private let gravatarImageView: CircularImageView = {
        let imageView = CircularImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.setContentHuggingPriority(UILayoutPriority(251), for: .horizontal)
        imageView.setContentHuggingPriority(UILayoutPriority(251), for: .vertical)
        return imageView
    }()
    private let nameLabel: UILabel = {
        let label = LikeUserTableViewCell.makeLabel(textStyle: .body)
        label.isUserInteractionEnabled = false
        label.contentMode = .topLeft
        return label
    }()
    private let usernameLabel: UILabel = {
        let label = LikeUserTableViewCell.makeLabel(textStyle: .subheadline)
        // The xib left user interaction on for this label.
        label.isUserInteractionEnabled = true
        label.contentMode = .left
        return label
    }()
    private let separatorView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    private lazy var separatorHeightConstraint = separatorView.heightAnchor.constraint(equalToConstant: 1)
    private lazy var separatorLeadingConstraint = separatorView.leadingAnchor.constraint(
        equalTo: contentView.leadingAnchor,
        constant: Constants.horizontalInset
    )

    static let estimatedRowHeight: CGFloat = 80
    private typealias Style = WPStyleGuide.Notifications

    // MARK: - View

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupSubviews()
        configureCell()
        registerForTraitChanges([UITraitDisplayScale.self]) { (self: LikeUserTableViewCell, _) in
            self.separatorHeightConstraint.constant = .hairlineBorderWidth(traitCollection: self.traitCollection)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public Methods

    func configure(withUser user: LikeUser, isLastRow: Bool = false) {
        nameLabel.text = user.displayName
        usernameLabel.text = String(format: Constants.usernameFormat, user.username)
        downloadGravatarWithURL(user.avatarUrl)
        separatorLeadingConstraint.constant = isLastRow ? 0 : Constants.horizontalInset
    }
}

// MARK: - Private Extension

private extension LikeUserTableViewCell {

    func setupSubviews() {
        clipsToBounds = true
        preservesSuperviewLayoutMargins = true
        contentView.isOpaque = false
        contentView.clipsToBounds = true
        contentView.contentMode = .center
        contentView.preservesSuperviewLayoutMargins = true
        contentView.insetsLayoutMarginsFromSafeArea = false

        let labelsStackView = UIStackView(arrangedSubviews: [nameLabel, usernameLabel])
        labelsStackView.translatesAutoresizingMaskIntoConstraints = false
        labelsStackView.isOpaque = false
        labelsStackView.axis = .vertical
        labelsStackView.alignment = .top
        labelsStackView.setContentHuggingPriority(.required, for: .vertical)

        let cellStackView = UIStackView(arrangedSubviews: [gravatarImageView, labelsStackView])
        cellStackView.translatesAutoresizingMaskIntoConstraints = false
        cellStackView.isOpaque = false
        cellStackView.alignment = .center
        cellStackView.spacing = 12

        contentView.addSubview(cellStackView)
        contentView.addSubview(separatorView)
        NSLayoutConstraint.activate([
            gravatarImageView.widthAnchor.constraint(equalToConstant: Constants.gravatarSize),
            gravatarImageView.widthAnchor.constraint(equalTo: gravatarImageView.heightAnchor),
            cellStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Constants.verticalInset),
            cellStackView.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor,
                constant: Constants.horizontalInset
            ),
            contentView.trailingAnchor.constraint(
                equalTo: cellStackView.trailingAnchor,
                constant: Constants.horizontalInset
            ),
            contentView.bottomAnchor.constraint(equalTo: cellStackView.bottomAnchor, constant: Constants.verticalInset),
            separatorLeadingConstraint,
            contentView.trailingAnchor.constraint(equalTo: separatorView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: separatorView.bottomAnchor),
            separatorHeightConstraint
        ])
    }

    static func makeLabel(textStyle: UIFont.TextStyle) -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isOpaque = false
        label.clipsToBounds = true
        label.font = .preferredFont(forTextStyle: textStyle)
        label.adjustsFontForContentSizeCategory = true
        label.setContentHuggingPriority(UILayoutPriority(251), for: .horizontal)
        label.setContentHuggingPriority(UILayoutPriority(251), for: .vertical)
        return label
    }

    func configureCell() {
        nameLabel.textColor = Style.blockTextColor
        usernameLabel.textColor = .secondaryLabel
        backgroundColor = Style.blockBackgroundColor
        separatorView.backgroundColor = Style.blockSeparatorColor
        separatorHeightConstraint.constant = .hairlineBorderWidth(traitCollection: traitCollection)
    }

    func downloadGravatarWithURL(_ url: String?) {
        // Always reset gravatar
        gravatarImageView.cancelImageDownload()
        gravatarImageView.image = .gravatarPlaceholderImage

        guard let url,
            let gravatarURL = URL(string: url)
        else {
            return
        }

        gravatarImageView.downloadImage(from: gravatarURL, placeholderImage: .gravatarPlaceholderImage)
    }

    enum Constants {
        static let gravatarSize: CGFloat = 46
        static let horizontalInset: CGFloat = 20
        static let verticalInset: CGFloat = 12
        static let usernameFormat = NSLocalizedString(
            "@%1$@",
            comment:
                "Label displaying the user's username preceded by an '@' symbol. %1$@ is a placeholder for the username."
        )
    }
}
