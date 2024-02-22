import UIKit
import Gridicons
import DesignSystem

class StatsLatestPostSummaryInsightsCell: StatsBaseCell, LatestPostSummaryConfigurable {
    private weak var siteStatsInsightsDelegate: SiteStatsInsightsDelegate?
    private typealias Style = WPStyleGuide.Stats
    private var lastPostInsight: StatsLastPostInsight?

    private let outerStackView = UIStackView()
    private let postStackView = UIStackView()
    private let statsStackView = UIStackView()
    private let postTitleLabel = UILabel()
    private let postTimestampLabel = UILabel()
    private let viewCountLabel = UILabel()
    private let likeCountLabel = UILabel()
    private let commentCountLabel = UILabel()
    private let postImageView = CachedAnimatedImageView()

    private let noDataLabel = UILabel()
    private let createPostButton = UIButton(type: .system)

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

    override func prepareForReuse() {
        super.prepareForReuse()

        toggleNoData(show: false)
    }

    // MARK: - View Configuration

    private func configureView() {
        selectionStyle = .none

        configureOuterStackView()
        contentView.addSubview(outerStackView)

        configurePostStackView()
        configureStatsStackView()
        outerStackView.addArrangedSubview(postStackView)
        outerStackView.addArrangedSubview(statsStackView)

        topConstraint = outerStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: StatsBaseCell.Metrics.padding)

        NSLayoutConstraint.activate([
            topConstraint!,
            outerStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -StatsBaseCell.Metrics.padding),
            outerStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: StatsBaseCell.Metrics.padding),
            outerStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -StatsBaseCell.Metrics.padding),
        ])

        configureNoDataViews()
    }

    private func configureOuterStackView() {
        outerStackView.translatesAutoresizingMaskIntoConstraints = false
        outerStackView.axis = .vertical
        outerStackView.spacing = Metrics.outerStackViewSpacing
    }

    private func configurePostStackView() {
        postStackView.translatesAutoresizingMaskIntoConstraints = false
        postStackView.axis = .horizontal
        postStackView.alignment = .top
        postStackView.spacing = Metrics.postStackViewHorizontalSpacing

        let postInfoStackView = UIStackView()
        postInfoStackView.translatesAutoresizingMaskIntoConstraints = false
        postInfoStackView.axis = .vertical
        postInfoStackView.spacing = Metrics.postStackViewVerticalSpacing

        postTitleLabel.textColor = .text
        postTitleLabel.numberOfLines = 2
        postTitleLabel.font = .preferredFont(forTextStyle: .headline)

        postTimestampLabel.textColor = .textSubtle
        postTimestampLabel.font = .preferredFont(forTextStyle: .subheadline)
        postTimestampLabel.adjustsFontSizeToFitWidth = true

        postInfoStackView.addArrangedSubviews([postTitleLabel, postTimestampLabel])

        postImageView.contentMode = .scaleAspectFill
        postImageView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            postImageView.widthAnchor.constraint(equalToConstant: Metrics.thumbnailSize),
            postImageView.heightAnchor.constraint(equalTo: postImageView.widthAnchor)
        ])

        postImageView.layer.cornerRadius = Metrics.thumbnailCornerRadius
        postImageView.layer.masksToBounds = true

        postStackView.addArrangedSubviews([postInfoStackView, postImageView])
    }

    private func configureStatsStackView() {
        statsStackView.translatesAutoresizingMaskIntoConstraints = false
        statsStackView.axis = .horizontal
        statsStackView.alignment = .top
        statsStackView.spacing = Metrics.postStackViewHorizontalSpacing

        let viewsStack = makeVerticalStatsStackView(with: viewCountLabel, title: TextContent.views)
        let likesStack = makeVerticalStatsStackView(with: likeCountLabel, title: TextContent.likes)
        let commentsStack = makeVerticalStatsStackView(with: commentCountLabel, title: TextContent.comments)

        let divider1 = makeVerticalDivider()
        let divider2 = makeVerticalDivider()

        statsStackView.addArrangedSubviews([
            viewsStack,
            divider1,
            likesStack,
            divider2,
            commentsStack
        ])

        NSLayoutConstraint.activate([
            viewsStack.widthAnchor.constraint(equalTo: likesStack.widthAnchor),
            likesStack.widthAnchor.constraint(equalTo: commentsStack.widthAnchor),
            divider1.heightAnchor.constraint(equalTo: statsStackView.heightAnchor),
            divider2.heightAnchor.constraint(equalTo: statsStackView.heightAnchor)
        ])
    }

    private func makeVerticalStatsStackView(with countLabel: UILabel, title: String) -> UIStackView {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 0

        let topLabel = UILabel()
        topLabel.text = title
        topLabel.adjustsFontSizeToFitWidth = true
        topLabel.adjustsFontForContentSizeCategory = true
        Style.configureLabelAsCellValueTitle(topLabel)

        countLabel.adjustsFontSizeToFitWidth = true
        countLabel.adjustsFontForContentSizeCategory = true
        countLabel.text = "0"
        Style.configureLabelAsCellValue(countLabel)

        stackView.addArrangedSubviews([topLabel, countLabel])

        return stackView
    }

    private func makeVerticalDivider() -> UIView {
        let divider = UIView()
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.widthAnchor.constraint(equalToConstant: Metrics.dividerWidth).isActive = true

        WPStyleGuide.Stats.configureViewAsVerticalSeparator(divider)

        return divider
    }

    private func configureNoDataViews() {
        noDataLabel.font = .preferredFont(forTextStyle: .body)
        noDataLabel.textColor = .textSubtle
        noDataLabel.numberOfLines = 0
        noDataLabel.text = TextContent.noData

        createPostButton.setImage(.gridicon(.create), for: .normal)
        createPostButton.setTitle(TextContent.createPost, for: .normal)

        // Increase the padding between the image and title of the button
        createPostButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: Metrics.createPostButtonInset, bottom: 0, right: -Metrics.createPostButtonInset)
        createPostButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: Metrics.createPostButtonInset)

        createPostButton.addTarget(self, action: #selector(createPostTapped), for: .touchUpInside)
    }

    // MARK: - Public Configuration

    func configure(withInsightData lastPostInsight: StatsLastPostInsight?, chartData: StatsPostDetails?, andDelegate delegate: SiteStatsInsightsDelegate?) {
        siteStatsInsightsDelegate = delegate
        statSection = .insightsLatestPostSummary

        guard let lastPostInsight = lastPostInsight else {
            toggleNoData(show: true)
            return
        }

        postTitleLabel.text = lastPostInsight.title

        let formatter = RelativeDateTimeFormatter()
        let date = formatter.localizedString(for: lastPostInsight.publishedDate, relativeTo: Date())
        postTimestampLabel.text = String(format: TextContent.publishDate, date)

        configureFeaturedImage(url: lastPostInsight.featuredImageURL)

        viewCountLabel.text = lastPostInsight.viewsCount.abbreviatedString()
        likeCountLabel.text = lastPostInsight.likesCount.abbreviatedString()
        commentCountLabel.text = lastPostInsight.commentsCount.abbreviatedString()
    }

    // Switches out the no data views into the main stack view if we have no data.
    //
    private func toggleNoData(show: Bool) {
        if !show && outerStackView.subviews.contains(noDataLabel) {
            noDataLabel.removeFromSuperview()
            createPostButton.removeFromSuperview()
            outerStackView.addArrangedSubviews([postStackView, statsStackView])
            outerStackView.alignment = .fill
        } else if show && outerStackView.subviews.contains(postStackView) {
            postStackView.removeFromSuperview()
            statsStackView.removeFromSuperview()
            outerStackView.addArrangedSubviews([noDataLabel, createPostButton])
            outerStackView.alignment = .leading
        }
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

    // MARK: - Actions

    @objc func createPostTapped() {
        siteStatsInsightsDelegate?.showCreatePost?()
    }

    // MARK: - Constants

    private enum Metrics {
        static let outerStackViewSpacing: CGFloat = Length.Padding.double
        static let postStackViewHorizontalSpacing: CGFloat = Length.Padding.double
        static let postStackViewVerticalSpacing: CGFloat = Length.Padding.single
        static let createPostButtonInset: CGFloat = Length.Padding.single
        static let thumbnailSize: CGFloat = 68.0
        static let thumbnailCornerRadius: CGFloat = Length.Padding.half
        static let dividerWidth: CGFloat = 1.0
    }

    private enum TextContent {
        static let noData = NSLocalizedString("stats.insights.latestPostSummary.noData", value: "Check back when you’ve published your first post!", comment: "Prompt shown in the 'Latest Post Summary' stats card if a user hasn't yet published anything.")
        static let createPost = NSLocalizedString("stats.insights.latestPostSummary.createPost", value: "Create Post", comment: "Title of button shown in Stats prompting the user to create a post on their site.")
        static let publishDate = NSLocalizedString("stats.insights.latestPostSummary.publishDate", value: "Published %@", comment: "Publish date of a post displayed in Stats. Placeholder will be replaced with a localized relative time, e.g. 2 days ago")
        static let views = NSLocalizedString("stats.insights.latestPostSummary.views", value: "Views", comment: "Title for Views count in Latest Post Summary stats card.")
        static let likes = NSLocalizedString("stats.insights.latestPostSummary.likes", value: "Likes", comment: "Title for Likes count in Latest Post Summary stats card.")
        static let comments = NSLocalizedString("stats.insights.latestPostSummary.comments", value: "Comments", comment: "Title for Comments count in Latest Post Summary stats card.")
    }
}
