import UIKit
import DesignSystem
import Inject

final class StatsTrafficBarChartCell: UITableViewCell {

    // MARK: - UI

    private let contentStackView = UIStackView()

    private let labelsStackView = UIStackView()
    private let titleStackView = UIStackView()
    private let numberLabel = UILabel()
    private let titleLabel = UILabel()
    private let differenceLabel = UILabel()

    private let chartContainerView = UIView()

    private let filterTabBar = FilterTabBar()

    // MARK: - Properties

    private var tabsData = [BarChartTabData]()
    private var chartData: [BarChartDataConvertible] = []
    private var chartStyling: [TrafficBarChartStyling] = []
    private var period: StatsPeriodUnit?

    // MARK: - Configure

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    internal override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        updateChartView()
    }

    func configure(tabsData: [BarChartTabData],
                   barChartData: [BarChartDataConvertible] = [],
                   barChartStyling: [TrafficBarChartStyling] = [],
                   period: StatsPeriodUnit? = nil) {
        self.tabsData = tabsData
        self.chartData = barChartData
        self.chartStyling = barChartStyling
        self.period = period

        updateLabels()
        updateButtons()
        updateChartView()
    }
}

private extension StatsTrafficBarChartCell {
    @objc func selectedFilterDidChange(_ filterBar: FilterTabBar) {
        updateLabels()
        updateChartView()
    }

    func updateLabels() {
        let tabData = tabsData[filterTabBar.selectedIndex]
        titleLabel.text = tabData.tabTitle
        numberLabel.text = tabData.tabData.abbreviatedString()
        differenceLabel.attributedText = differenceAttributedString(tabData)
    }

    func updateButtons() {
        filterTabBar.items = tabsData
    }

    func updateChartView() {
        let filterSelectedIndex = filterTabBar.selectedIndex

        guard chartData.count > filterSelectedIndex, chartStyling.count > filterSelectedIndex else {
            return
        }

        let configuration = StatsTrafficBarChartConfiguration(data: chartData[filterSelectedIndex],
                                                              styling: chartStyling[filterSelectedIndex],
                                                              analyticsGranularity: period?.analyticsGranularity)
        let chartView =  Inject.ViewHost(StatsTrafficBarChartView(configuration: configuration))

        resetChartContainerView()
        chartView.translatesAutoresizingMaskIntoConstraints = false
        chartContainerView.addSubview(chartView)
        chartContainerView.accessibilityElements = [chartView]
        chartContainerView.pinSubviewToAllEdges(chartView)
    }

    func resetChartContainerView() {
        for subview in chartContainerView.subviews {
            subview.removeFromSuperview()
        }
    }
}

// MARK: - Setup Views

private extension StatsTrafficBarChartCell {
    func setupViews() {
        setupContentView()
        setupContentStackView()
        setupLabels()
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
        contentStackView.spacing = Length.Padding.split
        contentView.addSubview(contentStackView)
        contentView.pinSubviewToAllEdges(contentStackView)
    }

    func setupLabels() {
        labelsStackView.axis = .vertical
        labelsStackView.alignment = .leading
        labelsStackView.spacing = 0
        labelsStackView.isLayoutMarginsRelativeArrangement = true
        labelsStackView.layoutMargins = .init(top: Length.Padding.single, left: Length.Padding.double, bottom: 0, right: Length.Padding.double)
        contentStackView.addArrangedSubview(labelsStackView)

        titleStackView.axis = .horizontal
        titleStackView.alignment = .firstBaseline
        titleStackView.spacing = Length.Padding.single
        contentStackView.addArrangedSubview(titleStackView)
        titleStackView.addArrangedSubviews([numberLabel, titleLabel])

        titleLabel.font = .preferredFont(forTextStyle: .body)
        numberLabel.font = .preferredFont(forTextStyle: .largeTitle).semibold()

        labelsStackView.addArrangedSubviews([titleStackView, differenceLabel])
    }

    func setupChart() {
        contentStackView.addArrangedSubview(chartContainerView)
        chartContainerView.widthAnchor.constraint(equalTo: contentView.widthAnchor).isActive = true
    }

    func setupButtons() {
        contentStackView.addArrangedSubview(filterTabBar)
        filterTabBar.widthAnchor.constraint(equalTo: contentStackView.widthAnchor).isActive = true
        filterTabBar.tabBarHeight = 40
        filterTabBar.equalWidthFill = .fillEqually
        filterTabBar.equalWidthSpacing = Length.Padding.single
        filterTabBar.tabSizingStyle = .equalWidths
        filterTabBar.tintColor = UIColor.DS.Foreground.primary
        filterTabBar.selectedTitleColor = UIColor.DS.Foreground.primary
        filterTabBar.deselectedTabColor = UIColor.DS.Foreground.secondary
        filterTabBar.tabSeparatorPlacement = .top
        filterTabBar.tabsFont = UIFont.preferredFont(forTextStyle: .caption2)
        filterTabBar.tabsSelectedFont = UIFont.preferredFont(forTextStyle: .caption2)
        filterTabBar.tabButtonInsets = UIEdgeInsets(top: Length.Padding.single, left: Length.Padding.half, bottom: Length.Padding.single, right: Length.Padding.half)
        filterTabBar.tabSeparatorPadding = Length.Padding.single
        filterTabBar.addTarget(self, action: #selector(selectedFilterDidChange(_:)), for: .valueChanged)
    }
}

// MARK: - Difference

private extension StatsTrafficBarChartCell {
    enum DifferenceStrings {
        static let weekHigher = NSLocalizedString("stats.traffic.label.weekDifference.higher",
                                                  value: "%@ higher than the previous 7-days\n",
                                                  comment: "Stats views higher than previous 7 days")
        static let weekLower = NSLocalizedString("stats.traffic.label.weekDifference.lower",
                                                 value: "%@ lower than the previous 7-days\n",
                                                 comment: "Stats views lower than previous 7 days")

        static let monthHigher = NSLocalizedString("stats.traffic.label.monthDifference.higher",
                                                   value: "%@ higher than the previous month\n",
                                                   comment: "Stats views higher than previous month")
        static let monthLower = NSLocalizedString("stats.traffic.label.monthDifference.lower",
                                                  value: "%@ lower than the previous month\n",
                                                  comment: "Stats views lower than previous month")

        static let yearHigher = NSLocalizedString("stats.traffic.label.yearDifference.higher",
                                                  value: "%@ higher than the previous year\n",
                                                  comment: "Stats views higher than previous year")
        static let yearLower = NSLocalizedString("stats.traffic.label.yearDifference.lower",
                                                 value: "%@ lower than the previous year\n",
                                                 comment: "Stats views lower than previous year")
    }

    func differenceAttributedString(_ data: BarChartTabData) -> NSAttributedString? {
        guard let differenceText = differenceText(data) else {
            return nil
        }

        let defaultAttributes = [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .footnote), NSAttributedString.Key.foregroundColor: UIColor.DS.Foreground.secondary]
        let differenceColor = data.difference > 0 ? UIColor.DS.Foreground.success : UIColor.DS.Foreground.error
        let differenceLabel = differenceLabel(data)
        let attributedString = NSMutableAttributedString(
            string: String(format: differenceText, differenceLabel),
            attributes: defaultAttributes
        )

        let str = attributedString.string as NSString
        let range = str.range(of: differenceLabel)

        attributedString.addAttributes(
            [.foregroundColor: differenceColor,
             .font: UIFont.preferredFont(forTextStyle: .footnote)
            ],
            range: NSRange(location: range.location, length: differenceLabel.count)
        )

        return attributedString
    }

    func differenceText(_ data: BarChartTabData) -> String? {
        switch data.period {
        case .week:
            if data.difference > 0 {
                return DifferenceStrings.weekHigher
            } else if data.difference < 0 {
                return DifferenceStrings.weekLower
            }
        case .month:
            if data.difference > 0 {
                return DifferenceStrings.monthHigher
            } else if data.difference < 0 {
                return DifferenceStrings.monthLower
            }
        case .year:
            if data.difference > 0 {
                return DifferenceStrings.yearHigher
            } else if data.difference < 0 {
                return DifferenceStrings.yearLower
            }
        default:
            return nil
        }

        return nil
    }

    func differenceLabel(_ data: BarChartTabData) -> String {
        // We want to show something like "+10.2K (+5%)" if we have a percentage difference and "1.2K" if we don't.
        //
        // Negative cases automatically appear with a negative sign "-10.2K (-5%)" by using `abbreviatedString()`.
        // `abbreviatedString()` also handles formatting big numbers, i.e. 10,200 will become 10.2K.
        let formatter = NumberFormatter()
        formatter.locale = .current
        let plusSign = data.difference <= 0 ? "" : "\(formatter.plusSign ?? "")"

        if data.differencePercent != 0 {
            let stringFormat = NSLocalizedString(
                "stats.traffic.differenceLabelWithPercentage",
                value: "%1$@%2$@ (%3$@%%)",
                comment: "Text for the Stats Traffic Overview stat difference label. Shows the change from the previous period, including the percentage value. E.g.: +12.3K (5%). %1$@ is the placeholder for the change sign ('-', '+', or none). %2$@ is the placeholder for the change numerical value. %3$@ is the placeholder for the change percentage value, excluding the % sign."
            )
            return String.localizedStringWithFormat(
                stringFormat,
                plusSign,
                data.difference.abbreviatedString(),
                data.differencePercent.abbreviatedString()
            )
        } else {
            let stringFormat = NSLocalizedString(
                "stats.traffic.differenceLabelWithoutPercentage",
                value: "%1$@%2$@",
                comment: "Text for the Stats Traffic Overview stat difference label. Shows the change from the previous period. E.g.: +12.3K. %1$@ is the placeholder for the change sign ('-', '+', or none). %2$@ is the placeholder for the change numerical value."
            )
            return String.localizedStringWithFormat(
                stringFormat,
                plusSign,
                data.difference.abbreviatedString()
            )
        }
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
