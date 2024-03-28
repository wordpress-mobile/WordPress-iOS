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

        updateButtons()
        updateChartView()
    }
}

private extension StatsTrafficBarChartCell {
    @objc func selectedFilterDidChange(_ filterBar: FilterTabBar) {
        updateChartView()
        siteStatsPeriodDelegate?.barChartTabSelected?(filterBar.selectedIndex)
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
