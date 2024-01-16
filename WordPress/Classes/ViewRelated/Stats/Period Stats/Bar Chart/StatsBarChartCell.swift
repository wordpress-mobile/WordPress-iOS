import UIKit
import DesignSystem

final class StatsBarChartCell: UITableViewCell {

    // MARK: - UI

    private let contentStackView = UIStackView()

    private let titleStackView = UIStackView()
    private let numberLabel = UILabel()
    private let titleLabel = UILabel()

    private let chartView = UIView()

    private let filterTabBar = FilterTabBar()

    // MARK: - Properties

    private var tabsData = [BarChartTabData]()
    private var chartData: [BarChartDataConvertible] = []
    private var chartStyling: [BarChartStyling] = []
    private weak var statsBarChartViewDelegate: StatsBarChartViewDelegate?
    private var period: StatsPeriodUnit?

    // MARK: - Configure

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func configure(tabsData: [BarChartTabData],
                   barChartData: [BarChartDataConvertible] = [],
                   barChartStyling: [BarChartStyling] = [],
                   period: StatsPeriodUnit? = nil,
                   statsBarChartViewDelegate: StatsBarChartViewDelegate? = nil) {
        self.tabsData = tabsData
        self.chartData = barChartData
        self.chartStyling = barChartStyling
        self.statsBarChartViewDelegate = statsBarChartViewDelegate
        self.period = period

        updateLabels()
        updateButtons()
    }
}

private extension StatsBarChartCell {
    @objc func selectedFilterDidChange(_ filterBar: FilterTabBar) {
        updateLabels()
    }

    func updateLabels() {
        let tabData = tabsData[filterTabBar.selectedIndex]
        titleLabel.text = tabData.tabTitle
        numberLabel.text = tabData.tabData.abbreviatedString()
    }

    func updateButtons() {
        filterTabBar.items = tabsData
    }
}

// MARK: - Setup Views

private extension StatsBarChartCell {
    func setupViews() {
        setupContentView()
        setupContentStackView()
        setupTitle()
        setupChart()
        setupButtons()
    }

    func setupContentView() {
        contentView.backgroundColor = UIColor.DS.Background.primary
    }

    func setupContentStackView() {
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.axis = .vertical
        contentStackView.alignment = .leading
        contentView.addSubview(contentStackView)
        contentView.pinSubviewToAllEdges(contentStackView)
    }

    func setupTitle() {
        titleStackView.translatesAutoresizingMaskIntoConstraints = false
        titleStackView.axis = .horizontal
        titleStackView.alignment = .firstBaseline
        titleStackView.isLayoutMarginsRelativeArrangement = true
        titleStackView.layoutMargins = .init(top: Length.Padding.single, left: Length.Padding.double, bottom: Length.Padding.single, right: Length.Padding.double)
        titleStackView.spacing = Length.Padding.single
        contentStackView.addArrangedSubview(titleStackView)
        titleStackView.addArrangedSubviews([numberLabel, titleLabel])

        titleLabel.font = .preferredFont(forTextStyle: .body)
        numberLabel.font = .preferredFont(forTextStyle: .largeTitle).semibold()
    }

    func setupChart() {
        chartView.heightAnchor.constraint(equalToConstant: 250).isActive = true
        chartView.backgroundColor = .red
        contentStackView.addArrangedSubview(chartView)
    }

    func setupButtons() {
        contentStackView.addArrangedSubview(filterTabBar)
        filterTabBar.widthAnchor.constraint(equalTo: contentStackView.widthAnchor).isActive = true
        filterTabBar.tabBarHeight = 40
        filterTabBar.equalWidthFill = .fillProportionally
        filterTabBar.equalWidthSpacing = Length.Padding.single
        filterTabBar.tabSizingStyle = .equalWidths
        filterTabBar.tintColor = UIColor.DS.Foreground.primary
        filterTabBar.selectedTitleColor = UIColor.DS.Foreground.primary
        filterTabBar.addTarget(self, action: #selector(selectedFilterDidChange(_:)), for: .valueChanged)
    }
}

struct BarChartTabData: FilterTabBarItem {
    var tabTitle: String
    var tabData: Int
    var tabDataStub: String?
    var difference: Int
    var differencePercent: Int
    var date: Date?
    var period: StatsPeriodUnit?
    var analyticsStat: WPAnalyticsStat?

    private(set) var accessibilityHint: String?

    init(tabTitle: String,
         tabData: Int,
         tabDataStub: String? = nil,
         difference: Int,
         differencePercent: Int,
         date: Date? = nil,
         period: StatsPeriodUnit? = nil,
         analyticsStat: WPAnalyticsStat? = nil,
         accessibilityHint: String? = nil) {
        self.tabTitle = tabTitle
        self.tabData = tabData
        self.tabDataStub = tabDataStub
        self.difference = difference
        self.differencePercent = differencePercent
        self.date = date
        self.period = period
        self.analyticsStat = analyticsStat
    }

    var title: String {
        return self.tabTitle
    }

    var accessibilityIdentifier: String {
        return self.tabTitle.localizedLowercase
    }

    var accessibilityLabel: String? {
        tabTitle
    }
}
