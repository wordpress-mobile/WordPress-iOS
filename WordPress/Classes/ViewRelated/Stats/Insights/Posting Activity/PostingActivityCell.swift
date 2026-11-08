import UIKit
import WordPressKit
import WordPressShared

class PostingActivityCell: StatsBaseCell, Accessible {

    // MARK: - Properties

    private let monthsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.distribution = .fillEqually
        stackView.spacing = 12
        stackView.setContentCompressionResistancePriority(.required, for: .vertical)
        return stackView
    }()

    private let viewMoreLabel = UILabel.makeStatsLabel(text: "View more", textStyle: .body, textAlignment: .left)

    private let legendView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private let topSeparatorLine = makeSeparator()
    private let bottomSeparatorLine = makeSeparator()

    private let viewMoreView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        return view
    }()

    private let viewMoreButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .clear
        return button
    }()

    private typealias Style = WPStyleGuide.Stats

    private weak var siteStatsInsightsDelegate: SiteStatsInsightsDelegate?

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none
        contentView.clipsToBounds = true
        contentView.contentMode = .center
        contentView.backgroundColor = .white
        setUpViews()

        applyStyles()
        addLegend()
        prepareForVoiceOver()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUpViews() {
        let legendContainer = UIView()
        legendContainer.translatesAutoresizingMaskIntoConstraints = false
        legendContainer.addSubview(legendView)

        let disclosureImageView = UIImageView(image: UIImage(systemName: "chevron.forward"))
        disclosureImageView.translatesAutoresizingMaskIntoConstraints = false
        disclosureImageView.contentMode = .scaleAspectFit
        disclosureImageView.tintColor = .secondaryLabel
        disclosureImageView.setContentHuggingPriority(UILayoutPriority(251), for: .horizontal)
        disclosureImageView.setContentHuggingPriority(UILayoutPriority(251), for: .vertical)
        viewMoreView.addSubview(viewMoreLabel)
        viewMoreView.addSubview(disclosureImageView)

        viewMoreButton.addTarget(self, action: #selector(didTapViewMoreButton), for: .touchUpInside)

        [monthsStackView, legendContainer, viewMoreView, viewMoreButton, topSeparatorLine, bottomSeparatorLine]
            .forEach(contentView.addSubview)

        let topConstraint = monthsStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8)
        NSLayoutConstraint.activate([
            topConstraint,
            monthsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            contentView.trailingAnchor.constraint(equalTo: monthsStackView.trailingAnchor, constant: 20),
            monthsStackView.heightAnchor.constraint(equalToConstant: 135),

            legendContainer.topAnchor.constraint(equalTo: monthsStackView.bottomAnchor, constant: 8),
            legendContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: legendContainer.trailingAnchor),
            legendContainer.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
            legendView.topAnchor.constraint(equalTo: legendContainer.topAnchor),
            legendView.leadingAnchor.constraint(equalTo: legendContainer.leadingAnchor),
            legendContainer.trailingAnchor.constraint(equalTo: legendView.trailingAnchor),
            legendContainer.bottomAnchor.constraint(equalTo: legendView.bottomAnchor),

            viewMoreView.topAnchor.constraint(equalTo: legendContainer.bottomAnchor),
            viewMoreView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: viewMoreView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: viewMoreView.bottomAnchor),
            viewMoreView.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),

            viewMoreLabel.topAnchor.constraint(equalTo: viewMoreView.topAnchor, constant: 12),
            viewMoreLabel.leadingAnchor.constraint(equalTo: viewMoreView.leadingAnchor, constant: 16),
            viewMoreView.bottomAnchor.constraint(equalTo: viewMoreLabel.bottomAnchor, constant: 12),
            disclosureImageView.leadingAnchor.constraint(equalTo: viewMoreLabel.trailingAnchor, constant: 16),
            viewMoreView.trailingAnchor.constraint(equalTo: disclosureImageView.trailingAnchor, constant: 16),
            disclosureImageView.centerYAnchor.constraint(equalTo: viewMoreView.centerYAnchor),
            disclosureImageView.widthAnchor.constraint(equalToConstant: 9),
            disclosureImageView.heightAnchor.constraint(equalToConstant: 16),

            viewMoreButton.topAnchor.constraint(equalTo: viewMoreView.topAnchor),
            viewMoreButton.leadingAnchor.constraint(equalTo: viewMoreView.leadingAnchor),
            viewMoreButton.trailingAnchor.constraint(equalTo: viewMoreView.trailingAnchor),
            viewMoreButton.bottomAnchor.constraint(equalTo: viewMoreView.bottomAnchor),

            topSeparatorLine.topAnchor.constraint(equalTo: contentView.topAnchor),
            topSeparatorLine.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: topSeparatorLine.trailingAnchor),

            bottomSeparatorLine.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: bottomSeparatorLine.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomSeparatorLine.bottomAnchor)
        ])
        self.topConstraint = topConstraint
    }

    private static func makeSeparator() -> UIView {
        let view = UIView.makeStatsSeparator()
        view.backgroundColor = UIColor(white: 0.667, alpha: 1)
        return view
    }

    func configure(withData monthsData: [[PostingStreakEvent]], andDelegate delegate: SiteStatsInsightsDelegate?) {
        siteStatsInsightsDelegate = delegate
        statSection = .insightsPostingActivity
        addMonths(monthsData: monthsData)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        removeExistingMonths()
    }

    func prepareForVoiceOver() {
        viewMoreButton.accessibilityLabel =
            NSLocalizedString("View more", comment: "Accessibility label for viewing more posting activity.")
        viewMoreButton.accessibilityHint = NSLocalizedString(
            "Tap to view more details.",
            comment: "Accessibility hint for a button that opens a new view with more details."
        )
    }

    override var accessibilityElements: [Any]? {
        get {
            [headingLabel] + monthsStackView.arrangedSubviews + [viewMoreButton].compactMap { $0 }
        }
        set {}
    }
}

// MARK: - Private Extension

private extension PostingActivityCell {

    func applyStyles() {
        viewMoreView.backgroundColor = .secondarySystemGroupedBackground
        viewMoreLabel.text = NSLocalizedString("View more", comment: "Label for viewing more posting activity.")
        viewMoreLabel.textColor = Style.actionTextColor
        Style.configureCell(self)
        Style.configureViewAsSeparator(topSeparatorLine)
        Style.configureViewAsSeparator(bottomSeparatorLine)
    }

    func addLegend() {
        let legend = PostingActivityLegend()
        legendView.addArrangedSubview(legend)
    }

    func addMonths(monthsData: [[PostingStreakEvent]]) {
        for monthData in monthsData {
            let monthView = PostingActivityMonth()
            monthView.configure(monthData: monthData)
            monthsStackView.addArrangedSubview(monthView)
        }
    }

    func removeExistingMonths() {
        monthsStackView.arrangedSubviews.forEach {
            monthsStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
    }

    @objc func didTapViewMoreButton(_ sender: UIButton) {
        WPAppAnalytics.track(.statsViewMoreTappedPostingActivity)
        siteStatsInsightsDelegate?.showPostingActivityDetails?()
    }
}
