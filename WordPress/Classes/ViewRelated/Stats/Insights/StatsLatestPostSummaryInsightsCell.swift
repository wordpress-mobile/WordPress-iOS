import UIKit


class StatsLatestPostSummaryInsightsCell: StatsBaseCell, LatestPostSummaryConfigurable {
    private weak var siteStatsInsightsDelegate: SiteStatsInsightsDelegate?
    private typealias Style = WPStyleGuide.Stats
    private var lastPostInsight: StatsLastPostInsight?
    private var lastPostDetails: StatsPostDetails?
    private var postTitle = StatSection.noPostTitle

    private var postTitleLabel: UILabel!
    private var postTimestampLabel: UILabel!
    private var viewCountLabel: UILabel!
    private var likeCountLabel: UILabel!
    private var commentCountLabel: UILabel!
    private var postImageView: CachedAnimatedImageView!

    lazy var imageLoader: ImageLoader = {
        return ImageLoader(imageView: postImageView, gifStrategy: .mediumGIFs)
    }()

    // MARK: - Initialization

    required override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        configureView()
    }

    required init(coder: NSCoder) {
        fatalError()
    }

    // MARK: - View Configuration

    private func configureView() {
        let stackView = makeOuterStackView()
        contentView.addSubview(stackView)

        let postStackView = makePostStackView()
        stackView.addArrangedSubview(postStackView)

        topConstraint = stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: StatsBaseCell.Metrics.padding)

        NSLayoutConstraint.activate([
            topConstraint,
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -StatsBaseCell.Metrics.padding),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: StatsBaseCell.Metrics.padding),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -StatsBaseCell.Metrics.padding),
        ])
    }

    private func makeOuterStackView() -> UIStackView {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = Metrics.outerStackViewSpacing

        return stackView
    }

    private func makePostStackView() -> UIStackView {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.alignment = .top
        stackView.spacing = Metrics.postStackViewHorizontalSpacing

        let postInfoStackView = UIStackView()
        postInfoStackView.translatesAutoresizingMaskIntoConstraints = false
        postInfoStackView.axis = .vertical
        postInfoStackView.spacing = Metrics.postStackViewVerticalSpacing

        postTitleLabel = UILabel()
        postTitleLabel.textColor = .text
        postTitleLabel.numberOfLines = 2
        postTitleLabel.font = .preferredFont(forTextStyle: .headline)

        postTimestampLabel = UILabel()
        postTimestampLabel.textColor = .textSubtle
        postTimestampLabel.font = .preferredFont(forTextStyle: .body)

        postInfoStackView.addArrangedSubviews([postTitleLabel, postTimestampLabel])

        postImageView = CachedAnimatedImageView()
        postImageView.contentMode = .scaleAspectFill
        postImageView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            postImageView.widthAnchor.constraint(equalToConstant: Metrics.thumbnailSize),
            postImageView.heightAnchor.constraint(equalTo: postImageView.widthAnchor)
        ])

        postImageView.layer.cornerRadius = Metrics.thumbnailCornerRadius
        postImageView.layer.masksToBounds = true

        stackView.addArrangedSubviews([postInfoStackView, postImageView])

        return stackView
    }

    // MARK: - Public Configuration

    func configure(withInsightData lastPostInsight: StatsLastPostInsight?, chartData: StatsPostDetails?, andDelegate delegate: SiteStatsInsightsDelegate?) {
        siteStatsInsightsDelegate = delegate
        statSection = .insightsLatestPostSummary

        guard let lastPostInsight = lastPostInsight else {
            // Old cell shows Create Post if there's no latest post
            return
        }

        postTitleLabel.text = lastPostInsight.title

        let formatter = RelativeDateTimeFormatter()
        let date = formatter.localizedString(for: lastPostInsight.publishedDate, relativeTo: Date())
        postTimestampLabel.text = String(format: TextContent.publishDate, date)

        configureFeaturedImage(url: lastPostInsight.featuredImageURL)
    }

    private func configureFeaturedImage(url: URL?) {
        if let url = url,
           let siteID = SiteStatsInformation.sharedInstance.siteID?.intValue,
           let blog = try? Blog.lookup(withID: siteID, in: ContextManager.shared.mainContext) {
            postImageView.isHidden = false

            let host = MediaHost(with: blog, failure: { error in
                DDLogError("Failed to create media host: \(error.localizedDescription)")
            })

            imageLoader.loadImage(with: url, from: host, preferredSize: CGSize(width: Metrics.thumbnailSize, height: Metrics.thumbnailSize))
        } else {
            postImageView.isHidden = true
        }
    }

    private enum Metrics {
        static let outerStackViewSpacing: CGFloat = 16.0
        static let postStackViewHorizontalSpacing: CGFloat = 16.0
        static let postStackViewVerticalSpacing: CGFloat = 8.0
        static let thumbnailSize: CGFloat = 68.0
        static let thumbnailCornerRadius: CGFloat = 4.0
    }

    private enum TextContent {
        static let publishDate = NSLocalizedString("stats.insights.latestPostSummary.publishDate", value: "Published %@",  comment: "Publish date of a post displayed in Stats. Placeholder will be replaced with a localized relative time, e.g. 2 days ago")
    }
}
