import Foundation
import WordPressShared
import WordPressUI
import Gravatar

class NoteBlockUserTableViewCell: NoteBlockTableViewCell {
    typealias EventHandler = (() -> Void)

    // MARK: - Public Properties
    @objc var onFollowClick: EventHandler?
    @objc var onUnfollowClick: EventHandler?

    @objc var isFollowEnabled: Bool {
        set {
            if newValue {
                innerStackView.addArrangedSubview(btnFollow)
            } else {
                btnFollow.removeFromSuperview()
            }
        }
        get {
            btnFollow.superview != nil
        }
    }
    @objc var isFollowOn: Bool {
        set {
            btnFollow.isSelected = newValue
            configureAccesibility()
        }
        get {
            btnFollow.isSelected
        }
    }

    @objc var name: String? {
        set {
            nameLabel.text = newValue
        }
        get {
            nameLabel.text
        }
    }
    @objc var blogTitle: String? {
        set {
            blogLabel.text = newValue
        }
        get {
            blogLabel.text
        }
    }

    // MARK: - Public Methods
    @objc func downloadGravatarWithURL(_ url: URL?) {
        if url == gravatarURL {
            return
        }

        let gravatar = url.flatMap { AvatarURL(url: $0) }
        gravatarImageView.downloadGravatar(gravatar, placeholder: .gravatarPlaceholderImage, animate: true)

        gravatarURL = url
    }

    // MARK: - View Methods

    override func prepareForReuse() {
        super.prepareForReuse()
        gravatarURL = nil
        gravatarImageView.cancelImageDownload()
        gravatarImageView.image = nil
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setupSubviews()

        WPStyleGuide.Notifications.configureFollowButton(btnFollow)

        backgroundColor = WPStyleGuide.Notifications.blockBackgroundColor

        nameLabel.textColor = WPStyleGuide.Notifications.blockTextColor

        blogLabel.textColor = UIAppColor.neutral(.shade50)
        blogLabel.adjustsFontSizeToFitWidth = false

        applyFonts()
        // The block fonts follow the window's horizontal size class. The cell's own size class changes when
        // it enters a window, and on the notification detail screen it changes along with the window's.
        registerForTraitChanges([UITraitHorizontalSizeClass.self]) { (self: Self, _) in
            self.applyFonts()
        }

        configureAccesibility()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubviews() {
        btnFollow.addTarget(self, action: #selector(followWasPressed), for: .touchUpInside)

        innerStackView.addArrangedSubviews([nameLabel, blogLabel, btnFollow])

        let labelsContainerView = UIView()
        labelsContainerView.translatesAutoresizingMaskIntoConstraints = false
        labelsContainerView.backgroundColor = .clear
        labelsContainerView.addSubview(innerStackView)

        let stackView = UIStackView(arrangedSubviews: [gravatarImageView, labelsContainerView])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.isOpaque = false
        stackView.alignment = .top
        stackView.spacing = 12

        contentView.addSubview(stackView)
        contentView.pinSubviewToAllEdgeMargins(stackView)
        NSLayoutConstraint.activate([
            innerStackView.topAnchor.constraint(
                equalTo: labelsContainerView.topAnchor,
                constant: Metrics.labelsTopOffset
            ),
            innerStackView.leadingAnchor.constraint(equalTo: labelsContainerView.leadingAnchor),
            labelsContainerView.trailingAnchor.constraint(equalTo: innerStackView.trailingAnchor),
            labelsContainerView.bottomAnchor.constraint(equalTo: innerStackView.bottomAnchor),
            btnFollow.widthAnchor.constraint(equalToConstant: Metrics.followButtonWidth),
            gravatarWidthConstraint,
            gravatarHeightConstraint
        ])

        registerForTraitChanges([UITraitHorizontalSizeClass.self, UITraitVerticalSizeClass.self]) { (self: Self, _) in
            self.gravatarWidthConstraint.constant = self.gravatarSize
            self.gravatarHeightConstraint.constant = self.gravatarSize
        }
    }

    private func applyFonts() {
        let horizontalSizeClass = (window ?? self).traitCollection.horizontalSizeClass
        btnFollow.titleLabel?.font = WPStyleGuide.Notifications.blockRegularFont(for: horizontalSizeClass)
        nameLabel.font = WPStyleGuide.Notifications.blockBoldFont(for: horizontalSizeClass)
        blogLabel.font = WPStyleGuide.Notifications.blockRegularFont(for: horizontalSizeClass)
    }

    // MARK: - Actions
    @objc func followWasPressed(_ sender: AnyObject) {
        ReachabilityUtils.onAvailableInternetConnectionDo {
            configureAccesibility()

            if let listener = isFollowOn ? onUnfollowClick : onFollowClick {
                listener()
            }
            isFollowOn.toggle()
        }
    }

    // MARK: - Private
    private func configureAccesibility() {
        isFollowOn ? configureAsSelected() : configureAsUnSelected()
    }

    private func configureAsUnSelected() {
        btnFollow.accessibilityLabel = Follow.title
        btnFollow.accessibilityHint = Follow.hint
    }

    private func configureAsSelected() {
        btnFollow.accessibilityLabel = Follow.selectedTitle
        btnFollow.accessibilityHint = Follow.selectedHint
    }

    fileprivate var gravatarURL: URL?

    // MARK: - Subviews
    fileprivate let nameLabel: UILabel = {
        let label = NoteBlockUserTableViewCell.makeLabel()
        label.isUserInteractionEnabled = false
        label.contentMode = .topLeft
        return label
    }()
    fileprivate let blogLabel: UILabel = {
        let label = NoteBlockUserTableViewCell.makeLabel()
        // The xib left user interaction on for this label.
        label.isUserInteractionEnabled = true
        label.contentMode = .left
        return label
    }()
    fileprivate let btnFollow: UIButton = {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Button", for: .normal)
        return button
    }()
    fileprivate let gravatarImageView: CircularImageView = {
        let imageView = CircularImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.setContentHuggingPriority(UILayoutPriority(251), for: .horizontal)
        imageView.setContentHuggingPriority(UILayoutPriority(251), for: .vertical)
        return imageView
    }()
    fileprivate let innerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.isOpaque = false
        stackView.axis = .vertical
        stackView.alignment = .top
        stackView.setContentHuggingPriority(.required, for: .vertical)
        return stackView
    }()

    private lazy var gravatarWidthConstraint = gravatarImageView.widthAnchor.constraint(equalToConstant: gravatarSize)
    private lazy var gravatarHeightConstraint: NSLayoutConstraint = {
        let constraint = gravatarImageView.heightAnchor.constraint(equalToConstant: gravatarSize)
        constraint.priority = UILayoutPriority(999)
        return constraint
    }()

    /// The gravatar is smaller when either size class is compact.
    private var gravatarSize: CGFloat {
        let isCompact = traitCollection.horizontalSizeClass == .compact || traitCollection.verticalSizeClass == .compact
        return isCompact ? Metrics.compactGravatarSize : Metrics.gravatarSize
    }

    private static func makeLabel() -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isOpaque = false
        label.clipsToBounds = true
        label.setContentHuggingPriority(UILayoutPriority(251), for: .horizontal)
        label.setContentHuggingPriority(UILayoutPriority(251), for: .vertical)
        return label
    }

    private enum Metrics {
        static let gravatarSize: CGFloat = 54
        static let compactGravatarSize: CGFloat = 46
        static let followButtonWidth: CGFloat = 100
        static let labelsTopOffset: CGFloat = -2
    }
}
