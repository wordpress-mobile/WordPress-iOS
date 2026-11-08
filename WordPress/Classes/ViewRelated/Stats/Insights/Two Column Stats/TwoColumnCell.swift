import UIKit
import DesignSystem
import WordPressShared

class TwoColumnCell: StatsBaseCell, Accessible {

    // MARK: - Properties

    private let topSeparatorLine = makeSeparator()
    private let rowsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        return stackView
    }()
    private let viewMoreView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.setContentCompressionResistancePriority(.required, for: .vertical)
        return view
    }()
    private let viewMoreLabel: UILabel = {
        let label = UILabel.makeStatsLabel(text: "View more", textStyle: .body, textAlignment: .left)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        return label
    }()
    private let viewMoreButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .clear
        return button
    }()
    private let bottomSeparatorLine = makeSeparator()
    private var bottomConstraint: NSLayoutConstraint!

    private typealias Style = WPStyleGuide.Stats
    private var dataRows = [StatsTwoColumnRowData]()
    private weak var siteStatsInsightsDelegate: SiteStatsInsightsDelegate?

    override var accessibilityElements: [Any]? {
        get {
            [headingLabel, rowsStackView, viewMoreButton].compactMap { $0 }
        }

        set {}
    }

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none
        contentView.clipsToBounds = true
        contentView.contentMode = .center
        contentView.backgroundColor = .white
        setUpViews()

        applyStyles()
        prepareForVoiceOver()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUpViews() {
        let disclosureImageView = UIImageView(image: UIImage(systemName: "chevron.forward"))
        disclosureImageView.translatesAutoresizingMaskIntoConstraints = false
        disclosureImageView.contentMode = .scaleAspectFit
        disclosureImageView.tintColor = .secondaryLabel
        disclosureImageView.setContentHuggingPriority(UILayoutPriority(251), for: .horizontal)
        disclosureImageView.setContentHuggingPriority(UILayoutPriority(251), for: .vertical)

        viewMoreButton.addTarget(self, action: #selector(didTapViewMore), for: .touchUpInside)
        [viewMoreLabel, disclosureImageView, viewMoreButton].forEach(viewMoreView.addSubview)

        let elementsStackView = UIStackView(arrangedSubviews: [rowsStackView, viewMoreView])
        elementsStackView.translatesAutoresizingMaskIntoConstraints = false
        elementsStackView.axis = .vertical

        [elementsStackView, topSeparatorLine, bottomSeparatorLine].forEach(contentView.addSubview)

        let topConstraint = elementsStackView.topAnchor.constraint(equalTo: topSeparatorLine.bottomAnchor)
        bottomConstraint = contentView.bottomAnchor.constraint(
            greaterThanOrEqualTo: rowsStackView.bottomAnchor,
            constant: 16
        )
        NSLayoutConstraint.activate([
            topSeparatorLine.topAnchor.constraint(equalTo: contentView.topAnchor),
            topSeparatorLine.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: topSeparatorLine.trailingAnchor),

            topConstraint,
            elementsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: elementsStackView.trailingAnchor),
            bottomConstraint,

            bottomSeparatorLine.topAnchor.constraint(equalTo: elementsStackView.bottomAnchor),
            bottomSeparatorLine.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: bottomSeparatorLine.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomSeparatorLine.bottomAnchor),

            viewMoreView.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
            viewMoreLabel.topAnchor.constraint(equalTo: viewMoreView.topAnchor, constant: 12),
            viewMoreLabel.leadingAnchor.constraint(equalTo: viewMoreView.leadingAnchor, constant: 16),
            viewMoreView.bottomAnchor.constraint(equalTo: viewMoreLabel.bottomAnchor, constant: 12),
            disclosureImageView.leadingAnchor.constraint(equalTo: viewMoreLabel.trailingAnchor, constant: 16),
            viewMoreView.trailingAnchor.constraint(equalTo: disclosureImageView.trailingAnchor, constant: 16),
            disclosureImageView.centerYAnchor.constraint(equalTo: viewMoreView.centerYAnchor),
            disclosureImageView.widthAnchor.constraint(equalToConstant: 9),
            disclosureImageView.heightAnchor.constraint(equalToConstant: 15),

            viewMoreButton.topAnchor.constraint(equalTo: viewMoreView.topAnchor),
            viewMoreButton.leadingAnchor.constraint(equalTo: viewMoreView.leadingAnchor),
            viewMoreView.trailingAnchor.constraint(equalTo: viewMoreButton.trailingAnchor),
            viewMoreView.bottomAnchor.constraint(equalTo: viewMoreButton.bottomAnchor)
        ])
        self.topConstraint = topConstraint
    }

    private static func makeSeparator() -> UIView {
        let view = UIView.makeStatsSeparator()
        view.backgroundColor = UIColor(white: 0.667, alpha: 1)
        return view
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        removeRowsFromStackView(rowsStackView)
    }

    func configure(
        dataRows: [StatsTwoColumnRowData],
        statSection: StatSection,
        siteStatsInsightsDelegate: SiteStatsInsightsDelegate?
    ) {
        self.dataRows = dataRows
        self.statSection = statSection
        self.siteStatsInsightsDelegate = siteStatsInsightsDelegate

        addRows()
        toggleViewMore()
    }

    func prepareForVoiceOver() {
        viewMoreButton.accessibilityLabel =
            NSLocalizedString("View more", comment: "Accessibility label for View more button in Stats.")
        viewMoreButton.accessibilityHint = NSLocalizedString(
            "Tap to view more details.",
            comment: "Accessibility hint for a button that opens a new view with more details."
        )
    }
}

// MARK: - Private Extension

private extension TwoColumnCell {

    func applyStyles() {
        viewMoreView.backgroundColor = .secondarySystemGroupedBackground
        viewMoreLabel.text = NSLocalizedString("View more", comment: "Label for viewing more stats.")
        viewMoreLabel.textColor = Style.actionTextColor
        Style.configureCell(self)
        Style.configureViewAsSeparator(topSeparatorLine)
        Style.configureViewAsSeparator(bottomSeparatorLine)
        configureSpacing()
    }

    private func configureSpacing() {
        bottomConstraint.constant = .DS.Padding.double
        rowsStackView.spacing = .DS.Padding.single
    }

    func addRows() {
        guard !dataRows.isEmpty else {
            let row = StatsNoDataRow()
            row.configure(forType: .insights)
            rowsStackView.addArrangedSubview(row)
            return
        }

        for dataRow in dataRows {
            let row = StatsTwoColumnRow()
            row.configure(rowData: dataRow)
            rowsStackView.addArrangedSubview(row)
        }
    }

    func toggleViewMore() {
        let showViewMore = !dataRows.isEmpty && statSection == .insightsAnnualSiteStats
        viewMoreView.isHidden = !showViewMore
    }

    @objc func didTapViewMore(_ sender: UIButton) {
        guard let statSection else {
            return
        }

        captureAnalyticsEventsFor(statSection)
        siteStatsInsightsDelegate?.viewMoreSelectedForStatSection?(statSection)
    }

    // MARK: - Analytics support

    func captureAnalyticsEventsFor(_ statSection: StatSection) {
        if let event = statSection.analyticsViewMoreEvent {
            captureAnalyticsEvent(event)
        }
    }

    func captureAnalyticsEvent(_ event: WPAnalyticsStat) {
        if let blogIdentifier = SiteStatsInformation.sharedInstance.siteID {
            WPAppAnalytics.track(event, blogID: blogIdentifier)
        } else {
            WPAppAnalytics.track(event)
        }
    }
}
