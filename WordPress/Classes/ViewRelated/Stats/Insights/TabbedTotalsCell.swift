import UIKit
import WordPressUI
import WordPressShared

struct TabData: FilterTabBarItem, Equatable {
    var tabTitle: String
    var itemSubtitle: String
    var dataSubtitle: String
    var totalCount: String?
    var dataRows: [StatsTotalRowData]

    init(
        tabTitle: String,
        itemSubtitle: String,
        dataSubtitle: String,
        totalCount: String? = nil,
        dataRows: [StatsTotalRowData]
    ) {
        self.tabTitle = tabTitle
        self.itemSubtitle = itemSubtitle
        self.dataSubtitle = dataSubtitle
        self.totalCount = totalCount
        self.dataRows = dataRows
    }

    var title: String {
        self.tabTitle
    }

    var accessibilityIdentifier: String {
        self.tabTitle.localizedLowercase
    }
}

class TabbedTotalsCell: StatsBaseCell {

    // MARK: - Properties

    private let topSeparatorLine = makeSeparator()
    private let filterTabBar: FilterTabBar = {
        let filterTabBar = FilterTabBar()
        filterTabBar.backgroundColor = .white
        return filterTabBar
    }()
    private let labelsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        return stackView
    }()
    private let totalCountView = makeWhiteView()
    private let totalCountLabel = UILabel.makeStatsLabel(
        text: "Total: 9999",
        textStyle: .subheadline,
        textAlignment: .center
    )
    private let itemSubtitleLabel = makeSubtitleLabel(textAlignment: .left)
    private let dataSubtitleLabel = makeSubtitleLabel(textAlignment: .right)
    private let labelsContainer = makeWhiteView()
    private let rowsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        return stackView
    }()
    private let bottomSeparatorLine = makeSeparator()
    private let noResultsView: UIView = {
        let view = UIView()
        view.isHidden = true
        view.backgroundColor = .clear
        return view
    }()

    private lazy var noResultsViewController: NoResultsViewController = {
        let controller = NoResultsViewController.controller()
        controller.configure(
            title: NSLocalizedString(
                "No data yet",
                comment: "Text shown when there is no data to display in the stats list view."
            )
        )
        controller.hideImageView(true)
        return controller
    }()

    private var tabsData = [TabData]()
    private typealias Style = WPStyleGuide.Stats
    private weak var siteStatsInsightsDelegate: SiteStatsInsightsDelegate?
    private weak var siteStatsDetailsDelegate: SiteStatsDetailsDelegate?
    private var showTotalCount = false
    private var forDetails = false

    override var accessibilityElements: [Any]? {
        get {
            [headingLabel, filterTabBar, rowsStackView].compactMap { $0 }
        }
        set {}
    }

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none
        contentView.clipsToBounds = true
        contentView.contentMode = .center

        totalCountView.addSubview(totalCountLabel)
        labelsContainer.addSubview(itemSubtitleLabel)
        labelsContainer.addSubview(dataSubtitleLabel)
        [totalCountView, labelsContainer].forEach(labelsStackView.addArrangedSubview)

        let contentStackView = UIStackView(arrangedSubviews: [
            filterTabBar, labelsStackView, rowsStackView, noResultsView
        ])
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.axis = .vertical
        [contentStackView, topSeparatorLine, bottomSeparatorLine].forEach(contentView.addSubview)

        let topConstraint = contentStackView.topAnchor.constraint(equalTo: contentView.topAnchor)
        let bottomConstraint = contentView.bottomAnchor.constraint(equalTo: contentStackView.bottomAnchor)
        bottomConstraint.priority = UILayoutPriority(999)
        NSLayoutConstraint.activate([
            topConstraint,
            contentStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: contentStackView.trailingAnchor),
            bottomConstraint,

            filterTabBar.heightAnchor.constraint(equalToConstant: 46),

            totalCountLabel.topAnchor.constraint(equalTo: totalCountView.topAnchor, constant: 19),
            totalCountLabel.leadingAnchor.constraint(equalTo: totalCountView.leadingAnchor, constant: 16),
            totalCountView.trailingAnchor.constraint(equalTo: totalCountLabel.trailingAnchor, constant: 16),
            totalCountView.bottomAnchor.constraint(equalTo: totalCountLabel.bottomAnchor, constant: 19),

            itemSubtitleLabel.topAnchor.constraint(equalTo: labelsContainer.topAnchor, constant: 7),
            itemSubtitleLabel.leadingAnchor.constraint(equalTo: labelsContainer.leadingAnchor, constant: 16),
            labelsContainer.bottomAnchor.constraint(equalTo: itemSubtitleLabel.bottomAnchor, constant: 7),
            dataSubtitleLabel.topAnchor.constraint(equalTo: labelsContainer.topAnchor, constant: 7),
            labelsContainer.trailingAnchor.constraint(equalTo: dataSubtitleLabel.trailingAnchor, constant: 16),
            labelsContainer.bottomAnchor.constraint(equalTo: dataSubtitleLabel.bottomAnchor, constant: 7),

            topSeparatorLine.topAnchor.constraint(equalTo: contentView.topAnchor),
            topSeparatorLine.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: topSeparatorLine.trailingAnchor),

            bottomSeparatorLine.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: bottomSeparatorLine.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomSeparatorLine.bottomAnchor)
        ])
        self.topConstraint = topConstraint
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private static func makeSeparator() -> UIView {
        let view = UIView.makeStatsSeparator()
        view.backgroundColor = UIColor(white: 0.667, alpha: 1)
        return view
    }

    private static func makeWhiteView() -> UIView {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }

    private static func makeSubtitleLabel(textAlignment: NSTextAlignment) -> UILabel {
        UILabel.makeStatsLabel(
            text: "Label",
            textStyle: .footnote,
            textColor: UIColor(white: 0.333, alpha: 1),
            textAlignment: textAlignment
        )
    }

    // MARK: - Configure

    func configure(
        tabsData: [TabData],
        statSection: StatSection? = nil,
        siteStatsInsightsDelegate: SiteStatsInsightsDelegate? = nil,
        siteStatsDetailsDelegate: SiteStatsDetailsDelegate? = nil,
        showTotalCount: Bool,
        selectedIndex: Int = 0,
        forDetails: Bool = false
    ) {
        self.tabsData = tabsData
        self.statSection = statSection
        self.siteStatsInsightsDelegate = siteStatsInsightsDelegate
        self.siteStatsDetailsDelegate = siteStatsDetailsDelegate
        self.showTotalCount = showTotalCount
        self.forDetails = forDetails
        bottomSeparatorLine.isHidden = forDetails
        setupFilterBar(selectedIndex: selectedIndex)
        addRowsForSelectedFilter()
        configureSubtitles()
        applyStyles()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        removeRowsFromStackView(rowsStackView)
        totalCountView.isHidden = false
        labelsStackView.isHidden = false
        noResultsView.isHidden = true
    }
}

// MARK: - FilterTabBar Support

private extension TabbedTotalsCell {

    func setupFilterBar(selectedIndex: Int) {
        if statSection == .insightsFollowersWordPress || statSection == .insightsFollowersEmail {
            WPStyleGuide.Stats.configureFilterTabBar(filterTabBar, forNewInsightsCard: true)
        } else {
            WPStyleGuide.Stats.configureFilterTabBar(filterTabBar, forTabbedCard: true)
        }
        filterTabBar.items = tabsData
        filterTabBar.setSelectedIndex(selectedIndex)
        filterTabBar.addTarget(self, action: #selector(selectedFilterDidChange(_:)), for: .valueChanged)
        toggleFilterTabBar()
    }

    func toggleFilterTabBar() {
        // If none of the tabs have data, hide the FilterTabBar.
        let noTabsData = !tabsData.contains { !$0.dataRows.isEmpty }
        filterTabBar.isHidden = noTabsData
    }

    @objc func selectedFilterDidChange(_ filterBar: FilterTabBar) {
        removeRowsFromStackView(rowsStackView)
        addRowsForSelectedFilter()
        configureSubtitles()
        siteStatsInsightsDelegate?.tabbedTotalsCellUpdated?()
        siteStatsDetailsDelegate?.tabbedTotalsCellUpdated?()
    }

    func toggleNoResults() {

        guard forDetails else {
            return
        }

        noResultsViewController.removeFromView()

        let showNoResults = tabsData[filterTabBar.selectedIndex].dataRows.isEmpty
        noResultsView.isHidden = !showNoResults

        guard showNoResults, let superview else {
            return
        }

        noResultsViewController.view.frame = noResultsView.bounds
        noResultsViewController.view.frame.size.height = superview.frame.height - filterTabBar.frame.height
        noResultsView.addSubview(noResultsViewController.view)
    }

    func addRowsForSelectedFilter() {

        if forDetails {
            toggleNoResults()
            return
        }

        addRows(
            tabsData[filterTabBar.selectedIndex].dataRows,
            toStackView: rowsStackView,
            forType: .insights,
            limitRowsDisplayed: true,
            rowDelegate: self,
            viewMoreDelegate: self
        )
    }
}

// MARK: - Private Methods

private extension TabbedTotalsCell {

    func applyStyles() {
        totalCountView.backgroundColor = .secondarySystemGroupedBackground
        labelsContainer.backgroundColor = .secondarySystemGroupedBackground
        Style.configureCell(self)
        Style.configureLabelAsTotalCount(totalCountLabel)
        Style.configureViewAsSeparator(topSeparatorLine)
        Style.configureViewAsSeparator(bottomSeparatorLine)
    }

    func configureSubtitles() {
        let tabData = tabsData[filterTabBar.selectedIndex]

        totalCountLabel.text = tabData.totalCount
        itemSubtitleLabel.text = tabData.itemSubtitle
        dataSubtitleLabel.text = tabData.dataSubtitle
        Style.configureLabelAsSubtitle(itemSubtitleLabel)
        Style.configureLabelAsSubtitle(dataSubtitleLabel)

        let noData = tabData.dataRows.isEmpty
        totalCountView.isHidden = !showTotalCount || noData
        labelsStackView.isHidden = noData
    }
}

// MARK: - StatsTotalRowDelegate

extension TabbedTotalsCell: StatsTotalRowDelegate {

    func displayWebViewWithURL(_ url: URL) {
        siteStatsInsightsDelegate?.displayWebViewWithURL?(url)
        siteStatsDetailsDelegate?.displayWebViewWithURL?(url)
    }
}

// MARK: - ViewMoreRowDelegate

extension TabbedTotalsCell: ViewMoreRowDelegate {

    func viewMoreSelectedForStatSection(_ statSection: StatSection) {
        siteStatsInsightsDelegate?.viewMoreSelectedForStatSection?(statSection)
    }
}
