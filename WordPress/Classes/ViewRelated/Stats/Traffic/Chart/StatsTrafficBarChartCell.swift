import UIKit
import DesignSystem

final class StatsTrafficBarChartCell: UITableViewCell {

    // MARK: - UI

    private let contentStackView = UIStackView()

    private let differenceLabel = UILabel()

    private let chartContainerView = UIView()

    private let filterTabBar = FilterTabBar()

    // MARK: - Properties

    private var tabsData = [StatsTrafficBarChartTabData]()
    private var chartData: [BarChartDataConvertible] = []
    private var chartStyling: [StatsTrafficBarChartStyling] = []
    private var period: StatsPeriodUnit?
    private var unit: StatsPeriodUnit?
    private var chartView: StatsTrafficBarChartView?
    private weak var siteStatsPeriodDelegate: SiteStatsPeriodDelegate?

    // MARK: - Configure

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        updateChartView()
    }

    func configure(tabsData: [StatsTrafficBarChartTabData],
                   barChartData: [BarChartDataConvertible] = [],
                   barChartStyling: [StatsTrafficBarChartStyling] = [],
                   period: StatsPeriodUnit,
                   unit: StatsPeriodUnit,
                   siteStatsPeriodDelegate: SiteStatsPeriodDelegate?) {
        self.tabsData = tabsData
        self.chartData = barChartData
        self.chartStyling = barChartStyling
        self.period = period
        self.unit = unit
        self.siteStatsPeriodDelegate = siteStatsPeriodDelegate

        updateLabels()
        updateButtons()
        updateChartView()
    }
}

private extension StatsTrafficBarChartCell {
    @objc func selectedFilterDidChange(_ filterBar: FilterTabBar) {
        updateLabels()
        updateChartView()
        siteStatsPeriodDelegate?.barChartTabSelected?(filterBar.selectedIndex)
    }

    func updateLabels() {
        let tabData = tabsData[filterTabBar.selectedIndex]
        differenceLabel.attributedText = differenceAttributedString(tabData)
    }

    func updateButtons() {
        let font = tabsFont(for: tabsData)
        filterTabBar.tabsFont = font
        filterTabBar.tabsSelectedFont = font
        filterTabBar.items = tabsData
    }

    func updateChartView() {
        let filterSelectedIndex = filterTabBar.selectedIndex

        guard chartData.count > filterSelectedIndex, chartStyling.count > filterSelectedIndex else {
            return
        }

        let chartData = chartData[filterSelectedIndex]
        let styling = chartStyling[filterSelectedIndex]

        if chartView == nil {
            let chartView = StatsTrafficBarChartView(barChartData: chartData, styling: styling)

            resetChartContainerView()
            chartView.translatesAutoresizingMaskIntoConstraints = false
            chartContainerView.addSubview(chartView)
            chartContainerView.accessibilityElements = [chartView]
            chartContainerView.pinSubviewToAllEdges(chartView, insets: UIEdgeInsets(top: .DS.Padding.split, left: 0, bottom: 0, right: 0))
            self.chartView = chartView
        } else {
            self.chartView?.update(barChartData: chartData, styling: styling)
        }
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
        contentStackView.spacing = .DS.Padding.split
        contentView.addSubview(contentStackView)
        contentView.pinSubviewToAllEdges(contentStackView)
    }

    func setupChart() {
        contentStackView.addArrangedSubview(chartContainerView)
        chartContainerView.heightAnchor.constraint(equalToConstant: 150).isActive = true
        chartContainerView.widthAnchor.constraint(equalTo: contentView.widthAnchor).isActive = true
    }

    func setupButtons() {
        contentStackView.addArrangedSubview(filterTabBar)
        filterTabBar.widthAnchor.constraint(equalTo: contentStackView.widthAnchor).isActive = true
        filterTabBar.tabBarHeight = 56
        filterTabBar.equalWidthFill = .fillEqually
        filterTabBar.equalWidthSpacing = .DS.Padding.single
        filterTabBar.tabSizingStyle = .equalWidths
        filterTabBar.tintColor = UIColor.DS.Foreground.primary
        filterTabBar.selectedTitleColor = UIColor.DS.Foreground.primary
        filterTabBar.deselectedTabColor = UIColor.DS.Foreground.secondary
        filterTabBar.tabSeparatorPlacement = .top
        filterTabBar.tabsFont = tabsFont()
        filterTabBar.tabsSelectedFont = tabsFont()
        filterTabBar.tabAttributedButtonInsets = UIEdgeInsets(top: .DS.Padding.single, left: .DS.Padding.half, bottom: .DS.Padding.single, right: .DS.Padding.half)
        filterTabBar.tabSeparatorPadding = .DS.Padding.single
        filterTabBar.addTarget(self, action: #selector(selectedFilterDidChange(_:)), for: .valueChanged)
    }

    func tabsFont(for data: [StatsTrafficBarChartTabData] = []) -> UIFont {
        if (tabsData.first { $0.tabTitle.count > 8 } != nil) {
            return UIFont.preferredFont(forTextStyle: .caption2, compatibleWith: .init(preferredContentSizeCategory: .large))
        } else {
            return UIFont.preferredFont(forTextStyle: .footnote, compatibleWith: .init(preferredContentSizeCategory: .large))
        }
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

    func differenceAttributedString(_ data: StatsTrafficBarChartTabData) -> NSAttributedString? {
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

    func differenceText(_ data: StatsTrafficBarChartTabData) -> String? {
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

    func differenceLabel(_ data: StatsTrafficBarChartTabData) -> String {
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

struct StatsTrafficBarChartTabData: FilterTabBarItem, Equatable {
    var tabTitle: String
    var tabData: Int
    var tabDataStub: String?
    var difference: Int
    var differencePercent: Int
    var date: Date?
    var period: StatsPeriodUnit?

    init(tabTitle: String,
         tabData: Int,
         tabDataStub: String? = nil,
         difference: Int,
         differencePercent: Int,
         date: Date? = nil,
         period: StatsPeriodUnit? = nil
    ) {
        self.tabTitle = tabTitle
        self.tabData = tabData
        self.tabDataStub = tabDataStub
        self.difference = difference
        self.differencePercent = differencePercent
        self.date = date
        self.period = period
    }

    var title: String {
        return self.tabTitle
    }

    var attributedTitle: NSAttributedString? {
        let attributedTitle = NSMutableAttributedString(string: tabTitle)
        attributedTitle.addAttributes([.font: UIFont.DS.font(.footnote)],
                                      range: NSMakeRange(0, attributedTitle.length))

        let dataString: String = {
            return tabDataStub ?? tabData.abbreviatedString()
        }()

        let attributedData = NSMutableAttributedString(string: dataString)
        attributedData.addAttributes([.font: UIFont.DS.font(.bodyLarge(.emphasized))],
                                     range: NSMakeRange(0, attributedData.length))

        attributedTitle.append(NSAttributedString(string: "\n"))
        attributedTitle.append(attributedData)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 0.9
        paragraphStyle.alignment = .center
        attributedTitle.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: attributedTitle.length))

        return attributedTitle
    }

    var accessibilityIdentifier: String {
        return self.tabTitle.localizedLowercase
    }

    var accessibilityLabel: String? {
        tabTitle
    }

    var accessibilityValue: String? {
        return tabDataStub != nil ? "" : "\(tabData)"
    }
}
