class ReaderTagCell: UICollectionViewCell {

    @IBOutlet private weak var contentStackView: UIStackView!
    @IBOutlet private weak var headerStackView: UIStackView!
    @IBOutlet private weak var siteLabel: UILabel!
    @IBOutlet private weak var postDateLabel: UILabel!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var summaryLabel: UILabel!
    @IBOutlet private weak var featuredImageView: CachedAnimatedImageView!
    @IBOutlet private weak var countsLabel: UILabel!
    @IBOutlet private weak var likeButton: UIButton!
    @IBOutlet private weak var menuButton: UIButton!

    private lazy var imageLoader = ImageLoader(imageView: featuredImageView)
    private var viewModel: ReaderTagCellViewModel?

    override func awakeFromNib() {
        super.awakeFromNib()
        setupStyles()
        contentStackView.setCustomSpacing(0, after: featuredImageView)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onSiteTitleTapped))
        headerStackView.addGestureRecognizer(tapGesture)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageLoader.prepareForReuse()
        resetHiddenViews()
    }

    func configure(parent: UIViewController?, post: ReaderPost, isLoggedIn: Bool) {
        viewModel = ReaderTagCellViewModel(parent: parent, post: post, isLoggedIn: isLoggedIn)

        let blogName = post.blogNameForDisplay()
        let postDate = post.shortDateForDisplay()
        let postTitle = post.titleForDisplay()
        let postSummary = post.summaryForDisplay(isPad: traitCollection.userInterfaceIdiom == .pad)
        let postCounts = post.countsForDisplay(isLoggedIn: isLoggedIn)

        siteLabel.text = blogName
        postDateLabel.text = postDate
        titleLabel.text = postTitle
        summaryLabel.text = postSummary
        countsLabel.text = postCounts

        siteLabel.isHidden = blogName == nil
        postDateLabel.isHidden = postDate == nil
        titleLabel.isHidden = postTitle == nil
        summaryLabel.isHidden = postSummary == nil
        countsLabel.isHidden = postCounts == nil

        configureLikeButton(with: post)
        loadFeaturedImage(with: post)
    }

    @objc private func onSiteTitleTapped() {
        viewModel?.onSiteTitleTapped()
    }

    @IBAction private func onLikeButtonTapped(_ sender: Any) {
        viewModel?.onLikeButtonTapped()
    }

    @IBAction private func onMenuButtonTapped(_ sender: UIButton) {
        viewModel?.onMenuButtonTapped(with: sender)
    }

    private struct Constants {
        static let likeText = NSLocalizedString("reader.tags.button.like",
                                                value: "Like",
                                                comment: "Text for the 'Like' button on the reader tag cell.")
        static let likedText = NSLocalizedString("reader.tags.button.liked",
                                                 value: "Liked",
                                                 comment: "Text for the 'Liked' button on the reader tag cell.")
        static let likeButtonImage = UIImage(named: "icon-reader-star-outline")?.withRenderingMode(.alwaysTemplate)
        static let likedButtonImage = UIImage(named: "icon-reader-star-fill")?.withRenderingMode(.alwaysTemplate)
    }

}

// MARK: - Private methods

private extension ReaderTagCell {

    func setupStyles() {
        siteLabel.font = WPStyleGuide.fontForTextStyle(.footnote, fontWeight: .semibold)
        postDateLabel.font = WPStyleGuide.fontForTextStyle(.footnote)
        postDateLabel.textColor = .secondaryLabel
        titleLabel.font = WPStyleGuide.fontForTextStyle(.headline, fontWeight: .semibold)
        summaryLabel.font = WPStyleGuide.fontForTextStyle(.footnote)
        countsLabel.font = WPStyleGuide.fontForTextStyle(.footnote)
        countsLabel.textColor = .secondaryLabel
        likeButton.tintColor = .secondaryLabel
        likeButton.titleLabel?.font = WPStyleGuide.fontForTextStyle(.footnote)
        menuButton.tintColor = .secondaryLabel
        featuredImageView.layer.cornerRadius = 5.0
    }

    func loadFeaturedImage(with post: ReaderPost) {
        guard let url = post.featuredImageURLForDisplay() else {
            featuredImageView.isHidden = true
            return
        }
        let imageSize = CGSize(width: featuredImageView.frame.width,
                                   height: featuredImageView.frame.height)
        let host = MediaHost(with: post, failure: { error in
            DDLogError(error)
        })
        imageLoader.loadImage(with: url, from: host, preferredSize: imageSize)
    }

    func resetHiddenViews() {
        siteLabel.isHidden = false
        titleLabel.isHidden = false
        summaryLabel.isHidden = false
        featuredImageView.isHidden = false
        countsLabel.isHidden = false
        likeButton.isHidden = false
    }

    func configureLikeButton(with post: ReaderPost) {
        let isLiked = post.isLiked
        likeButton.setTitle(isLiked ? Constants.likedText : Constants.likeText, for: .normal)
        likeButton.setImage(isLiked ? Constants.likedButtonImage : Constants.likeButtonImage, for: .normal)
        likeButton.tintColor = isLiked ? .jetpackGreen : .secondaryLabel
        likeButton.setTitleColor(likeButton.tintColor, for: .normal)
    }

}
