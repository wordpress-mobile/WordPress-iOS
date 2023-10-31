
class ReaderPostCardCell: UITableViewCell {

    // MARK: - Properties

    private let contentStackView = UIStackView()

    private let siteStackView = UIStackView()
    private let siteIconContainerView = UIView()
    private let siteIconImageView = UIImageView()
    private let siteIconBorderView = UIView()
    private let avatarContainerView = UIView()
    private let avatarImageView = UIImageView()
    private let siteTitleLabel = UILabel()
    private let postDateLabel = UILabel()

    private let postTitleLabel = UILabel()
    private let postSummaryLabel = UILabel()
    private let featuredImageView = CachedAnimatedImageView()
    private let postCountsLabel = UILabel()

    private let controlsStackView = UIStackView()
    private let reblogButton = UIButton()
    private let commentButton = UIButton()
    private let likeButton = UIButton()
    private let fillerView = UIView()
    private let menuButton = UIButton()

    private let separatorView = UIView()

    private lazy var imageLoader = ImageLoader(imageView: featuredImageView)
    private var viewModel: ReaderPostCardCellViewModel? {
        didSet {
            configureLabels()
            configureImages()
            configureButtons()
            configureAccessibility()
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageLoader.prepareForReuse()
        resetElements()
        addMissingViews()
        addViewConstraints()
    }

    func configure(with viewModel: ReaderPostCardCellViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Constants

    struct Constants {
        struct ContentStackView {
            static let margins: CGFloat = 16.0
            static let spacing: CGFloat = 8.0
            static let bottomAnchor: CGFloat = 2.0
        }

        struct SiteStackView {
            static let avatarSpacing: CGFloat = -4.0
            static let iconSpacing: CGFloat = 8.0
            static let siteTitleSpacing: CGFloat = 4.0
        }

        struct ControlsStackView {
            static let reblogSpacing: CGFloat = 16.0
            static let commentSpacing: CGFloat = 16.0
            static let likeSpacing: CGFloat = 8.0
            static let trailingConstraint: CGFloat = 10.0
            static let bottomConstraint: CGFloat = -ContentStackView.margins + 10.0
        }

        struct FeaturedImage {
            static let cornerRadius: CGFloat = 5.0
            static let heightAspectMultiplier: CGFloat = 239.0 / 358.0
        }

        struct Accessibility {
            static let siteStackViewHint = NSLocalizedString("reader.post.header.accessibility.hint",
                                                             value: "Opens the site details for the post.",
                                                             comment: "Accessibility hint for the site header on the reader post card cell")
            static let reblogButtonHint = NSLocalizedString("reader.post.button.reblog.accessibility.hint",
                                                            value: "Reblogs the post.",
                                                            comment: "Accessibility hint for the reblog button on the reader post card cell")
            static let commentButtonHint = NSLocalizedString("reader.post.button.comment.accessibility.hint",
                                                             value: "Opens the comments for the post.",
                                                             comment: "Accessibility hint for the comment button on the reader post card cell")
            static let likeButtonHint = NSLocalizedString("reader.post.button.like.accessibility.hint",
                                                          value: "Likes the post.",
                                                          comment: "Accessibility hint for the like button on the reader post card cell")
            static let likedButtonHint = NSLocalizedString("reader.post.button.liked.accessibility.hint",
                                                          value: "Unlikes the post.",
                                                          comment: "Accessibility hint for the liked button on the reader post card cell")
            static let menuButtonLabel = NSLocalizedString("reader.post.button.menu.accessibility.label",
                                                           value: "More",
                                                           comment: "Accessibility label for the more menu button on the reader post card cell")
            static let menuButtonHint = NSLocalizedString("reader.post.button.menu.accessibility.hint",
                                                          value: "Opens a menu with more actions.",
                                                          comment: "Accessibility hint for the site header on the reader post card cell")
        }

        static let iconImageSize: CGFloat = 20.0
        static let avatarPlaceholder = UIImage(named: "gravatar")
        static let siteIconPlaceholder = UIImage(named: "post-blavatar-placeholder")
        static let fillerViewHuggingPriority = UILayoutPriority(249.0)
        static let reblogButtonImage = UIImage(named: "icon-reader-reblog")?.withRenderingMode(.alwaysTemplate)
        static let commentButtonImage = UIImage(named: "icon-reader-post-comment")?.withRenderingMode(.alwaysTemplate)
        static let likeButtonImage = UIImage(named: "icon-reader-star-outline")?.withRenderingMode(.alwaysTemplate)
        static let likedButtonImage = UIImage(named: "icon-reader-star-fill")?.withRenderingMode(.alwaysTemplate)
        static let menuButtonImage = UIImage(named: "more-horizontal-mobile")?.withRenderingMode(.alwaysTemplate)
        static let buttonMinimumSize: CGFloat = 44.0
        static let reblogButtonText = NSLocalizedString("reader.post.button.reblog",
                                                        value: "Reblog",
                                                        comment: "Text for the 'Reblog' button on the reader post card cell.")
        static let commentButtonText = NSLocalizedString("reader.post.button.comment",
                                                         value: "Comment",
                                                         comment: "Text for the 'Comment' button on the reader post card cell.")
        static let likeButtonText = NSLocalizedString("reader.post.button.like",
                                                      value: "Like",
                                                      comment: "Text for the 'Like' button on the reader post card cell.")
        static let likedButtonText = NSLocalizedString("reader.post.button.liked",
                                                       value: "Liked",
                                                       comment: "Text for the 'Liked' button on the reader post card cell.")
        static let borderColor = UIColor(light: .systemBackground.darkVariant().withAlphaComponent(0.1),
                                         dark: .systemBackground.lightVariant().withAlphaComponent(0.2))
        static let borderWidth: CGFloat = 0.5
        static let imageSeparatorBorderWidth: CGFloat = 1.0
        static let separatorHeight: CGFloat = 0.5
        static let likeButtonIdentifier = "reader-like-button"
    }

}

// MARK: - Private methods

private extension ReaderPostCardCell {

    var usesAccessibilitySize: Bool {
        traitCollection.preferredContentSizeCategory.isAccessibilityCategory
    }

    func commonInit() {
        setupViews()
        addViewConstraints()
    }

    // MARK: - View setup

    func setupViews() {
        setupContentView()
        setupContentStackView()

        setupAvatarImage()
        setupSiteIconImage()
        setupSiteTitle()
        setupPostDate()
        setupSiteStackView()

        setupPostTitle()
        setupPostSummary()
        setupFeaturedImage()
        setupPostCounts()

        setupControlButtons()
        setupControlsStackView()

        setupSeparatorView()
    }

    func setupContentView() {
        contentView.backgroundColor = .systemBackground
    }

    func setupContentStackView() {
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.axis = .vertical
        contentStackView.alignment = .leading
        contentStackView.spacing = Constants.ContentStackView.spacing
        contentView.addSubview(contentStackView)
    }

    func setupAvatarImage() {
        setupIconImage(avatarImageView,
                       containerView: avatarContainerView,
                       image: Constants.avatarPlaceholder)
        avatarContainerView.addSubview(avatarImageView)
        siteStackView.addArrangedSubview(avatarContainerView)
    }

    func setupSiteIconImage() {
        setupIconImage(siteIconImageView,
                       containerView: siteIconContainerView,
                       image: Constants.siteIconPlaceholder)
        siteIconImageView.layer.masksToBounds = false
        siteIconBorderView.translatesAutoresizingMaskIntoConstraints = false
        siteIconBorderView.layer.frame = CGRect(x: 0, y: 0, width: Constants.iconImageSize, height: Constants.iconImageSize)
        siteIconBorderView.layer.cornerRadius = Constants.iconImageSize / 2.0
        siteIconBorderView.layer.borderWidth = Constants.borderWidth + Constants.imageSeparatorBorderWidth
        siteIconBorderView.layer.borderColor = UIColor.listForeground.cgColor
        siteIconBorderView.layer.masksToBounds = true
        siteIconBorderView.addSubview(siteIconImageView)
        siteIconContainerView.addSubview(siteIconBorderView)
        siteStackView.addArrangedSubview(siteIconContainerView)
    }

    func setupIconImage(_ imageView: UIImageView, containerView: UIView, image: UIImage?) {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = Constants.iconImageSize / 2.0
        imageView.layer.masksToBounds = true
        imageView.image = image
        imageView.contentMode = .scaleAspectFill
        imageView.layer.borderWidth = Constants.borderWidth
        imageView.layer.borderColor = Constants.borderColor.cgColor
        imageView.backgroundColor = .listForeground
    }

    func setupSiteTitle() {
        siteTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        siteTitleLabel.font = .preferredFont(forTextStyle: .subheadline).semibold()
        siteTitleLabel.numberOfLines = 1
        siteTitleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        siteStackView.addArrangedSubview(siteTitleLabel)
    }

    func setupPostDate() {
        postDateLabel.translatesAutoresizingMaskIntoConstraints = false
        postDateLabel.font = .preferredFont(forTextStyle: .footnote)
        postDateLabel.numberOfLines = 1
        postDateLabel.textColor = .secondaryLabel

        // if accessibility size
        if !usesAccessibilitySize {
            siteStackView.addArrangedSubview(postDateLabel)
        }
    }

    func setupSiteStackView() {
        siteStackView.translatesAutoresizingMaskIntoConstraints = false
        siteStackView.setCustomSpacing(Constants.SiteStackView.avatarSpacing, after: avatarContainerView)
        siteStackView.setCustomSpacing(Constants.SiteStackView.iconSpacing, after: siteIconContainerView)
        siteStackView.setCustomSpacing(Constants.SiteStackView.siteTitleSpacing, after: siteTitleLabel)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapSiteHeader))
        siteStackView.addGestureRecognizer(tapGesture)

        contentStackView.addArrangedSubview(siteStackView)

        if usesAccessibilitySize {
            contentStackView.addArrangedSubview(postDateLabel)
        }
    }

    func setupPostTitle() {
        postTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        postTitleLabel.font = .preferredFont(forTextStyle: .title3).semibold()
        postTitleLabel.numberOfLines = 2
        contentStackView.addArrangedSubview(postTitleLabel)
    }

    func setupPostSummary() {
        postSummaryLabel.translatesAutoresizingMaskIntoConstraints = false
        postSummaryLabel.font = .preferredFont(forTextStyle: .footnote)
        postSummaryLabel.numberOfLines = 3
        contentStackView.addArrangedSubview(postSummaryLabel)
    }

    func setupFeaturedImage() {
        featuredImageView.translatesAutoresizingMaskIntoConstraints = false
        featuredImageView.layer.cornerRadius = Constants.FeaturedImage.cornerRadius
        featuredImageView.layer.masksToBounds = true
        featuredImageView.contentMode = .scaleAspectFill
        featuredImageView.layer.borderWidth = Constants.borderWidth
        featuredImageView.layer.borderColor = Constants.borderColor.cgColor
        contentStackView.addArrangedSubview(featuredImageView)
    }

    func setupPostCounts() {
        postCountsLabel.font = .preferredFont(forTextStyle: .footnote)
        postCountsLabel.numberOfLines = 1
        postCountsLabel.textColor = .secondaryLabel
        contentStackView.addArrangedSubview(postCountsLabel)
    }

    func setupControlButton(_ button: UIButton, image: UIImage?, text: String? = nil, action: Selector) {
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = .secondaryLabel
        button.titleLabel?.font = .preferredFont(forTextStyle: .footnote)
        button.titleLabel?.lineBreakMode = .byTruncatingTail
        button.setImage(image, for: .normal)
        button.setTitleColor(.secondaryLabel, for: .normal)
        button.setTitle(text, for: .normal)
        button.addTarget(self, action: action, for: .touchUpInside)
        controlsStackView.addArrangedSubview(button)
    }

    func setupControlButtons() {
        if !usesAccessibilitySize {
            setupControlButton(reblogButton,
                               image: Constants.reblogButtonImage,
                               text: Constants.reblogButtonText,
                               action: #selector(didTapReblog))
        }
        setupControlButton(commentButton,
                           image: Constants.commentButtonImage,
                           text: Constants.commentButtonText,
                           action: #selector(didTapComment))
        setupControlButton(likeButton,
                           image: Constants.likeButtonImage,
                           text: Constants.likeButtonText,
                           action: #selector(didTapLike))
        setupFillerView()
        controlsStackView.addArrangedSubview(fillerView)
        setupControlButton(menuButton,
                           image: Constants.menuButtonImage,
                           action: #selector(didTapMore))
    }

    func setupFillerView() {
        fillerView.translatesAutoresizingMaskIntoConstraints = false
        fillerView.setContentHuggingPriority(Constants.fillerViewHuggingPriority, for: .horizontal)
        fillerView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }

    func setupControlsStackView() {
        controlsStackView.translatesAutoresizingMaskIntoConstraints = false
        controlsStackView.setCustomSpacing(Constants.ControlsStackView.reblogSpacing, after: reblogButton)
        controlsStackView.setCustomSpacing(Constants.ControlsStackView.commentSpacing, after: commentButton)
        controlsStackView.setCustomSpacing(Constants.ControlsStackView.likeSpacing, after: likeButton)
        contentView.addSubview(controlsStackView)
    }

    func setupSeparatorView() {
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        separatorView.backgroundColor = .separator
        contentView.addSubview(separatorView)
    }

    // MARK: - View constraints

    func addViewConstraints() {
        NSLayoutConstraint.activate(
            contentViewConstraints()
            + iconImageConstraints(avatarImageView, containerView: avatarContainerView)
            + siteIconImageConstraints()
            + featuredImageContraints()
            + buttonStackViewConstraints()
            + buttonConstraints()
            + separatorViewConstraints()
        )
    }

    func contentViewConstraints() -> [NSLayoutConstraint] {
        let margins = Constants.ContentStackView.margins
        return [
            contentStackView.leadingAnchor.constraint(equalTo: contentView.readableContentGuide.leadingAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: contentView.readableContentGuide.trailingAnchor),
            contentStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: margins),
            contentStackView.bottomAnchor.constraint(equalTo: controlsStackView.topAnchor,
                                                     constant: Constants.ContentStackView.bottomAnchor)
        ]
    }

    func iconImageConstraints(_ imageView: UIImageView, containerView: UIView) -> [NSLayoutConstraint] {
        return [
            containerView.heightAnchor.constraint(greaterThanOrEqualTo: imageView.heightAnchor),
            containerView.widthAnchor.constraint(greaterThanOrEqualTo: imageView.widthAnchor),
            imageView.heightAnchor.constraint(equalToConstant: Constants.iconImageSize),
            imageView.widthAnchor.constraint(equalToConstant: Constants.iconImageSize),
            imageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ]
    }

    func siteIconImageConstraints() -> [NSLayoutConstraint] {
        return [
            siteIconContainerView.heightAnchor.constraint(greaterThanOrEqualTo: siteIconBorderView.heightAnchor),
            siteIconContainerView.widthAnchor.constraint(greaterThanOrEqualTo: siteIconBorderView.widthAnchor),
            siteIconBorderView.heightAnchor.constraint(equalToConstant: Constants.iconImageSize + Constants.borderWidth + Constants.imageSeparatorBorderWidth),
            siteIconBorderView.widthAnchor.constraint(equalToConstant: Constants.iconImageSize + Constants.borderWidth + Constants.imageSeparatorBorderWidth),
            siteIconBorderView.centerXAnchor.constraint(equalTo: siteIconContainerView.centerXAnchor),
            siteIconBorderView.centerYAnchor.constraint(equalTo: siteIconContainerView.centerYAnchor),
            siteIconImageView.heightAnchor.constraint(equalToConstant: Constants.iconImageSize),
            siteIconImageView.widthAnchor.constraint(equalToConstant: Constants.iconImageSize),
            siteIconImageView.centerXAnchor.constraint(equalTo: siteIconBorderView.centerXAnchor),
            siteIconImageView.centerYAnchor.constraint(equalTo: siteIconBorderView.centerYAnchor),
        ]
    }

    func featuredImageContraints() -> [NSLayoutConstraint] {
        let heightAspectRatio = featuredImageView.heightAnchor.constraint(equalTo: featuredImageView.widthAnchor,
                                                                          multiplier: Constants.FeaturedImage.heightAspectMultiplier)
        heightAspectRatio.priority = .defaultHigh
        return [
            featuredImageView.widthAnchor.constraint(equalTo: contentStackView.widthAnchor),
            heightAspectRatio
        ]
    }

    func buttonStackViewConstraints() -> [NSLayoutConstraint] {
        return [
            controlsStackView.leadingAnchor.constraint(equalTo: contentStackView.leadingAnchor),
            controlsStackView.trailingAnchor.constraint(equalTo: contentStackView.trailingAnchor,
                                                        constant: Constants.ControlsStackView.trailingConstraint),
            controlsStackView.bottomAnchor.constraint(equalTo: separatorView.topAnchor,
                                                      constant: Constants.ControlsStackView.bottomConstraint),
            controlsStackView.heightAnchor.constraint(equalToConstant: Constants.buttonMinimumSize)
        ]
    }

    func buttonConstraints() -> [NSLayoutConstraint] {
        let minimumSize = Constants.buttonMinimumSize
        return [
            reblogButton.widthAnchor.constraint(greaterThanOrEqualToConstant: minimumSize),
            commentButton.widthAnchor.constraint(greaterThanOrEqualToConstant: minimumSize),
            likeButton.widthAnchor.constraint(greaterThanOrEqualToConstant: minimumSize),
            menuButton.widthAnchor.constraint(greaterThanOrEqualToConstant: minimumSize),
        ]
    }

    func separatorViewConstraints() -> [NSLayoutConstraint] {
        return [
            separatorView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            separatorView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            separatorView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: Constants.separatorHeight)
        ]
    }

    // MARK: - View configuration

    func configureLabels() {
        configureLabel(siteTitleLabel, text: viewModel?.siteTitle)
        configureLabel(postDateLabel, text: usesAccessibilitySize ? viewModel?.shortPostDate : viewModel?.postDate)
        configureLabel(postTitleLabel, text: viewModel?.postTitle)
        configureLabel(postSummaryLabel, text: viewModel?.postSummary)
        configureLabel(postCountsLabel, text: viewModel?.postCounts)
    }

    func configureLabel(_ label: UILabel, text: String?) {
        guard let text else {
            label.removeFromSuperview()
            return
        }
        label.setText(text)
    }

    func configureImages() {
        configureAvatar()
        configureSiteIcon()
        configureFeaturedImage()
    }

    func configureAvatar() {
        guard let viewModel, viewModel.isAvatarEnabled else {
            removeFromStackView(siteStackView, view: avatarContainerView)
            return
        }
        viewModel.downloadAvatarIcon(for: avatarImageView)
    }

    func configureSiteIcon() {
        guard let viewModel, viewModel.isSiteIconEnabled else {
            siteStackView.setCustomSpacing(Constants.SiteStackView.iconSpacing, after: avatarContainerView)
            removeFromStackView(siteStackView, view: siteIconContainerView)
            return
        }
        viewModel.downloadSiteIcon(for: siteIconImageView)
    }

    func configureFeaturedImage() {
        guard let viewModel, viewModel.isFeaturedImageEnabled else {
            removeFromStackView(siteStackView, view: featuredImageView)
            return
        }
        let imageViewSize = CGSize(width: featuredImageView.frame.width,
                                   height: featuredImageView.frame.height)
        viewModel.downloadFeaturedImage(with: imageLoader, size: imageViewSize)
    }

    func configureButtons() {
        guard let viewModel else {
            return
        }

        if !viewModel.isReblogEnabled {
            removeFromStackView(controlsStackView, view: reblogButton)
        }
        if !viewModel.isCommentsEnabled {
            removeFromStackView(controlsStackView, view: commentButton)
        }
        if viewModel.isLikesEnabled {
            configureLikeButton()
        } else {
            removeFromStackView(controlsStackView, view: likeButton)
        }
    }

    func configureLikeButton() {
        guard let isLiked = viewModel?.isPostLiked else {
            return
        }
        likeButton.setTitle(isLiked ? Constants.likedButtonText : Constants.likeButtonText, for: .normal)
        likeButton.setImage(isLiked ? Constants.likedButtonImage : Constants.likeButtonImage, for: .normal)
        likeButton.tintColor = isLiked ? .jetpackGreen : .secondaryLabel
        likeButton.setTitleColor(likeButton.tintColor, for: .normal)
    }

    // MARK: - Accessibility

    func configureAccessibility() {
        siteStackView.isAccessibilityElement = true
        siteStackView.accessibilityLabel = [viewModel?.siteTitle, viewModel?.shortPostDate].compactMap { $0 }.joined(separator: ", ")
        siteStackView.accessibilityHint = Constants.Accessibility.siteStackViewHint
        siteStackView.accessibilityTraits = .button

        postCountsLabel.accessibilityLabel = [viewModel?.likeCount, viewModel?.commentCount].compactMap { $0 }.joined(separator: ", ")

        reblogButton.accessibilityHint = Constants.Accessibility.reblogButtonHint
        commentButton.accessibilityHint = Constants.Accessibility.commentButtonHint
        likeButton.accessibilityHint = viewModel?.isPostLiked == true ? Constants.Accessibility.likedButtonHint : Constants.Accessibility.likeButtonHint
        likeButton.accessibilityIdentifier = Constants.likeButtonIdentifier
        menuButton.accessibilityLabel = Constants.Accessibility.menuButtonLabel
        menuButton.accessibilityHint = Constants.Accessibility.menuButtonHint
        accessibilityElements = [
            siteStackView, postTitleLabel, postSummaryLabel, postCountsLabel,
            reblogButton, commentButton, likeButton, menuButton
        ].filter { $0 != reblogButton || !self.usesAccessibilitySize } // skip reblog button if a11y size is active.
    }

    // MARK: - Cell reuse

    func addMissingViews() {
        let siteHeaderViews = [avatarContainerView, siteIconContainerView, siteTitleLabel, postDateLabel]
        let contentViews = [siteStackView, postTitleLabel, postSummaryLabel, featuredImageView, postCountsLabel]
        let controlViews = [reblogButton, commentButton, likeButton].filter {
            // skip reblog button if a11y size is active.
            $0 != reblogButton || !self.usesAccessibilitySize
        }

        siteHeaderViews.enumerated().forEach { (index, view) in
            addToStackView(siteStackView, view: view, index: index)
        }
        contentViews.enumerated().forEach { (index, view) in
            addToStackView(contentStackView, view: view, index: index)
        }
        controlViews.enumerated().forEach { (index, view) in
            addToStackView(controlsStackView, view: view, index: index)
        }

        siteStackView.setCustomSpacing(Constants.SiteStackView.avatarSpacing, after: avatarContainerView)
        siteStackView.setCustomSpacing(Constants.SiteStackView.iconSpacing, after: siteIconContainerView)
        siteStackView.setCustomSpacing(Constants.SiteStackView.siteTitleSpacing, after: siteTitleLabel)
        controlsStackView.setCustomSpacing(Constants.ControlsStackView.reblogSpacing, after: reblogButton)
        controlsStackView.setCustomSpacing(Constants.ControlsStackView.commentSpacing, after: commentButton)
        controlsStackView.setCustomSpacing(Constants.ControlsStackView.likeSpacing, after: likeButton)
    }

    func addToStackView(_ stackView: UIStackView, view: UIView, index: Int) {
        guard view.superview == nil, stackView.arrangedSubviews.count >= index else {
            return
        }
        stackView.insertArrangedSubview(view, at: index)
    }

    func removeFromStackView(_ stackView: UIStackView, view: UIView) {
        stackView.removeArrangedSubview(view)
        view.removeFromSuperview()
    }

    func resetElements() {
        avatarImageView.image = Constants.avatarPlaceholder
        siteIconImageView.image = Constants.siteIconPlaceholder
        siteTitleLabel.text = nil
        postDateLabel.text = nil
        postTitleLabel.text = nil
        postSummaryLabel.text = nil
        featuredImageView.image = nil
        postCountsLabel.text = nil
    }

    // MARK: - Button actions

    @objc func didTapSiteHeader() {
        viewModel?.showSiteDetails()
    }

    @objc func didTapReblog() {
        viewModel?.reblog()
    }

    @objc func didTapComment() {
        viewModel?.comment(with: self)
    }

    @objc func didTapLike() {
        viewModel?.toggleLike(with: self)
    }

    @objc func didTapMore() {
        viewModel?.showMore(with: menuButton)
    }

}
