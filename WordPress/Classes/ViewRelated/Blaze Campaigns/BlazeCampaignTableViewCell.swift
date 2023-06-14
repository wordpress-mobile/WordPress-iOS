final class BlazeCampaignTableViewCell: UITableViewCell, Reusable {

    // MARK: - Views

    private lazy var mainStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = Metrics.mainStackViewSpacing
        stackView.directionalLayoutMargins = Metrics.defaultMainStackViewLayoutMargins
        stackView.isLayoutMarginsRelativeArrangement = true
//        stackView.addBottomBorder(withColor: Colors.separatorColor, leadingMargin: Metrics.defaultMainStackViewLayoutMargins.leading)
        stackView.addArrangedSubviews([headerStackView, detailsOuterStackView])
        return stackView
    }()

    private lazy var headerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.addArrangedSubviews([statusView, UIView()])
        return stackView
    }()

    private lazy var statusView: DashboardBlazeCampaignStatusView = {
        let statusView = DashboardBlazeCampaignStatusView()
        statusView.translatesAutoresizingMaskIntoConstraints = false
        return statusView
    }()

    private lazy var detailsOuterStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.alignment = .top
        stackView.spacing = Metrics.detailsOuterStackViewSpacing
        stackView.addArrangedSubviews([detailsInnerStackView, featuredImageView])
        return stackView
    }()

    private lazy var detailsInnerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = Metrics.detailsInnerStackViewSpacing
        // FIXME: Add stats views as an arranged subview
        stackView.addArrangedSubviews([titleLabel])
        return stackView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontForContentSizeCategory = true
        label.adjustsFontSizeToFitWidth = true
        label.font = WPStyleGuide.fontForTextStyle(.subheadline, fontWeight: .semibold)
        label.numberOfLines = 0
        label.textColor = .text
        return label
    }()

    private lazy var featuredImageView: CachedAnimatedImageView = {
        let imageView = CachedAnimatedImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: Metrics.featuredImageSize),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor)
        ])

        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = Metrics.featuredImageCornerRadius
        return imageView
    }()

    // MARK: - Properties

    private lazy var imageLoader: ImageLoader = {
        return ImageLoader(imageView: featuredImageView, gifStrategy: .mediumGIFs)
    }()

    // MARK: - Initializers

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    // MARK: - Public

    func configure(with viewModel: DashboardBlazeCampaignViewModel, blog: Blog) {
        statusView.configure(with: viewModel.status)

        titleLabel.text = viewModel.title

        imageLoader.prepareForReuse()
        featuredImageView.isHidden = viewModel.imageURL == nil
        if let imageURL = viewModel.imageURL {
            let host = MediaHost(with: blog, failure: { error in
                WordPressAppDelegate.crashLogging?.logError(error)
            })

            let preferredSize = CGSize(width: featuredImageView.frame.width, height: featuredImageView.frame.height)
            imageLoader.loadImage(with: imageURL, from: host, preferredSize: preferredSize)
        }
    }

    // MARK: - Helpers

    private func commonInit() {
        setupViews()
        applyStyle()
    }

    private func applyStyle() {
        backgroundColor = .DS.Background.primary
    }

    private func setupViews() {
        contentView.addSubview(mainStackView)
        contentView.pinSubviewToAllEdges(mainStackView)
    }
}

private extension BlazeCampaignTableViewCell {

    enum Metrics {
        static let mainStackViewSpacing: CGFloat = 8
        static let detailsOuterStackViewSpacing: CGFloat = 16
        static let detailsInnerStackViewSpacing: CGFloat = 8
        static let defaultMainStackViewLayoutMargins: NSDirectionalEdgeInsets = .init(top: 14, leading: 16, bottom: 14, trailing: 16)
        static let featuredImageSize: CGFloat = 72
        static let featuredImageCornerRadius: CGFloat = 4
    }

    enum Colors {
        static let separatorColor: UIColor = .separator
    }
}
