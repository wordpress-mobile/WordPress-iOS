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

    override func awakeFromNib() {
        super.awakeFromNib()
        setupStyles()
        contentStackView.setCustomSpacing(0, after: featuredImageView)
        likeButton.setTitle(NSLocalizedString("reader.tags.button.like",
                                              value: "Like",
                                              comment: "Text for the 'Like' button on the reader tag cell."),
                            for: .normal)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageLoader.prepareForReuse()
        resetHiddenViews()
    }

    func configure(with post: ReaderPost, isLoggedIn: Bool) {
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
        loadFeaturedImage(with: post)
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

}
