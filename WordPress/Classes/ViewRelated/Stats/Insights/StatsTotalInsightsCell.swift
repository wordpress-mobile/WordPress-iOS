import UIKit
import WordPressShared

struct StatsTotalInsightsData {
    var count: Int
    var difference: Int? = nil
    var percentage: Int? = nil
    var sparklineData: [Int]? = nil
    var guideText: NSAttributedString? = nil

    // Used to allow a URL to be displayed in response to a guide being tapped
    var guideURL: URL? = nil

    var lastPostInsight: StatsLastPostInsight? = nil
    var statsSummaryType: StatsSummaryType? = nil

    public static func followersCount(insightsStore: StatsInsightsStore) -> StatsTotalInsightsData {
        return StatsTotalInsightsData(count: insightsStore.getTotalFollowerCount())
    }

    public static func createTotalInsightsData(periodSummary: StatsSummaryTimeIntervalData?,
                                               insightsStore: StatsInsightsStore,
                                               statsSummaryType: StatsSummaryType,
                                               periodEndDate: Date? = nil) -> StatsTotalInsightsData {

        guard let periodSummary = periodSummary else {
            return StatsTotalInsightsData(count: 0)
        }

        let splitSummaryTimeIntervalData = SiteStatsInsightsViewModel.splitStatsSummaryTimeIntervalData(periodSummary, periodEndDate: periodEndDate)

        var countKey: KeyPath<StatsSummaryData, Int>
        switch statsSummaryType {
        case .likes:
            countKey = \StatsSummaryData.likesCount
        case .comments:
            countKey = \StatsSummaryData.commentsCount
        default:
            return StatsTotalInsightsData(count: 0)
        }

        let sparklineData: [Int] = makeSparklineData(countKey: countKey, splitSummaryTimeIntervalData: splitSummaryTimeIntervalData)
        let data = SiteStatsInsightsViewModel.intervalData(periodSummary, summaryType: statsSummaryType, periodEndDate: periodEndDate)
        let guideText = makeTotalInsightsGuideText(lastPostInsight: insightsStore.getLastPostInsight(), statsSummaryType: statsSummaryType)
        let guideURL: URL? = statsSummaryType == .likes ? insightsStore.getLastPostInsight()?.url : nil

        return StatsTotalInsightsData(count: data.count, difference: data.difference, percentage: data.percentage, sparklineData: sparklineData, guideText: guideText, guideURL: guideURL, lastPostInsight: insightsStore.getLastPostInsight(), statsSummaryType: statsSummaryType)
    }

    static func makeSparklineData(countKey: KeyPath<StatsSummaryData, Int>, splitSummaryTimeIntervalData: [StatsSummaryTimeIntervalDataAsAWeek]) -> [Int] {
        var sparklineData = [Int]()
        splitSummaryTimeIntervalData.forEach { statsSummaryTimeIntervalDataAsAWeek in
            switch statsSummaryTimeIntervalDataAsAWeek {
            case .thisWeek(let data):
                for statsSummaryData in data.summaryData {
                    sparklineData.append(statsSummaryData[keyPath: countKey])
                }
            default:
                break
            }
        }

        return sparklineData
    }

    static func makeTotalInsightsGuideText(lastPostInsight: StatsLastPostInsight?, statsSummaryType: StatsSummaryType) -> NSAttributedString? {

        switch statsSummaryType {
        case .likes:
            guard let summary = lastPostInsight else {
                return nil
            }

            if summary.likesCount == 1 {
                return totalInsightsGuideAttributedString(text: TextContent.likesTotalGuideTextSingular, title: summary.title, count: 1)
            } else {
                return totalInsightsGuideAttributedString(text: TextContent.likesTotalGuideTextPlural, title: summary.title, count: summary.likesCount)
            }
        case .comments:
            return NSAttributedString(string: TextContent.commentsTotalGuideText)
        default:
            return nil
        }
    }

    private static func totalInsightsGuideAttributedString(text: String, title: String, count: Int) -> NSAttributedString {
        let countString = String(count)
        let formattedString = String.localizedStringWithFormat(text, title, countString)

        let attributedString = NSMutableAttributedString(string: formattedString)

        let textRange = NSMakeRange(0, formattedString.count)
        attributedString.addAttribute(.font, value: UIFont.preferredFont(forTextStyle: .subheadline), range: textRange)
        attributedString.addAttribute(.foregroundColor, value: UIColor.text, range: textRange)

        let titlePlaceholderRange = (text as NSString).range(of: "%1$@")
        let titleRange = NSMakeRange(titlePlaceholderRange.location, title.count)
        attributedString.addAttribute(.foregroundColor, value: UIColor.primary, range: titleRange)

        let formattedTitleString = String.localizedStringWithFormat(text, title, "%2$@")
        let countPlaceholderRange = (formattedTitleString as NSString).range(of: "%2$@")
        let countRange = NSMakeRange(countPlaceholderRange.location, countString.count)
        attributedString.addAttribute(.font, value: UIFont.preferredFont(forTextStyle: .subheadline).bold(), range: countRange)

        return attributedString
    }

    private enum TextContent {
        static let likesTotalGuideTextSingular = NSLocalizedString(
            "stats.insights.totalLikes.guideText.singular",
            value: "Your latest post %1$@ has received %2$@ like.",
            comment: "A hint shown to the user in stats informing the user that one of their posts has received a like. The %1$@ placeholder will be replaced with the title of a post, and the %2$@ will be replaced by the numeral one.")
        static let likesTotalGuideTextPlural = NSLocalizedString(
            "stats.insights.totalLikes.guideText.plural",
            value: "Your latest post %1$@ has received %2$@ likes.",
            comment: "A hint shown to the user in stats informing the user how many likes one of their posts has received. The %1$@ placeholder will be replaced with the title of a post, the %2$@ with the number of likes.")
        static let commentsTotalGuideText = NSLocalizedString("Tap \"View more\" to see your top commenters.", comment: "A hint shown to the user in stats telling them how to navigate to the Comments detail view.")
    }
}

class StatsTotalInsightsCell: StatsBaseCell {
    private weak var siteStatsInsightsDelegate: SiteStatsInsightsDelegate?
    private var lastPostInsight: StatsLastPostInsight?
    private var statsSummaryType: StatsSummaryType?
    private var guideURL: URL?
    private var guideText: NSAttributedString?

    private let outerStackView = UIStackView()
    private let topInnerStackView = UIStackView()
    private let guideView = UIView()
    private let guideViewLabel = UILabel()
    private let countLabel = UILabel()
    private let comparisonLabel = UILabel()
    private let graphView = SparklineView()

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

        countLabel.text = "0"
        graphView.data = []
        comparisonLabel.isHidden = true

        guideViewLabel.text = ""
        guideView.removeFromSuperview()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        rebuildGuideViewIfNeeded()
    }

    private func configureView() {
        selectionStyle = .none

        configureStackViews()
        configureGraphView()
        configureGuideView()
        configureLabels()
        configureConstraints()
    }

    private func configureStackViews() {
        outerStackView.translatesAutoresizingMaskIntoConstraints = false
        outerStackView.axis = .vertical
        outerStackView.spacing = Metrics.outerStackViewSpacing
        contentView.addSubview(outerStackView)

        topInnerStackView.axis = .horizontal
        topInnerStackView.spacing = Metrics.stackViewSpacing

        topInnerStackView.addArrangedSubviews([countLabel, graphView])
        outerStackView.addArrangedSubviews([topInnerStackView, comparisonLabel])
    }

    private func configureGraphView() {
        graphView.translatesAutoresizingMaskIntoConstraints = false
        graphView.setContentHuggingPriority(.required, for: .horizontal)
        graphView.setContentHuggingPriority(.required, for: .vertical)
    }

    private func configureGuideView() {
        guideView.backgroundColor = UIColor(light: .systemGray6, dark: .secondarySystemFill)
        guideView.translatesAutoresizingMaskIntoConstraints = false
        guideView.layer.cornerRadius = 10.0
        guideView.layer.masksToBounds = true

        guideViewLabel.translatesAutoresizingMaskIntoConstraints = false
        guideView.addSubview(guideViewLabel)

        guideViewLabel.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        guideView.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)

        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(guideTapped))
        guideView.addGestureRecognizer(gestureRecognizer)
    }

    private func configureLabels() {
        countLabel.font = WPStyleGuide.Stats.insightsCountFont
        countLabel.textColor = .text
        countLabel.text = "0"
        countLabel.adjustsFontForContentSizeCategory = true
        countLabel.adjustsFontSizeToFitWidth = true
        countLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        countLabel.setContentHuggingPriority(.required, for: .vertical)

        comparisonLabel.font = .preferredFont(forTextStyle: .subheadline)
        comparisonLabel.textColor = .textSubtle
        comparisonLabel.numberOfLines = 0

        guideViewLabel.font = .preferredFont(forTextStyle: .subheadline)
        guideViewLabel.textColor = .text
        guideViewLabel.numberOfLines = 0
        guideViewLabel.lineBreakMode = .byWordWrapping
    }

    private func configureConstraints() {
        topConstraint = outerStackView.topAnchor.constraint(equalTo: contentView.topAnchor)

        NSLayoutConstraint.activate([
            topConstraint!,
            outerStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -StatsBaseCell.Metrics.padding),
            outerStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: StatsBaseCell.Metrics.padding),
            outerStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -StatsBaseCell.Metrics.padding),
            graphView.widthAnchor.constraint(equalTo: graphView.heightAnchor, multiplier: Metrics.graphViewAspectRatio),
            graphView.heightAnchor.constraint(equalTo: countLabel.heightAnchor)
        ])

        guideView.pinSubviewToAllEdges(guideViewLabel, insets: UIEdgeInsets(allEdges: 16.0), priority: .required)
    }

    func configure(dataRow: StatsTotalInsightsData, statSection: StatSection, siteStatsInsightsDelegate: SiteStatsInsightsDelegate?) {
        self.guideURL = dataRow.guideURL

        self.statSection = statSection
        self.lastPostInsight = dataRow.lastPostInsight
        self.statsSummaryType = dataRow.statsSummaryType
        self.guideText = dataRow.guideText
        self.siteStatsInsightsDelegate = siteStatsInsightsDelegate
        self.siteStatsInsightDetailsDelegate = siteStatsInsightsDelegate

        graphView.data = dataRow.sparklineData ?? []
        graphView.chartColor = chartColor(for: dataRow.difference ?? 0)

        countLabel.text = dataRow.count.abbreviatedString()

        updateGuideView(withGuideText: dataRow.guideText)
        updateComparisonLabel(withCount: dataRow.count, difference: dataRow.difference, percentage: dataRow.percentage)
    }

    private func updateGuideView(withGuideText guideText: NSAttributedString?) {
        if let guideText = guideText,
            guideText.string.isEmpty == false {
            outerStackView.addArrangedSubview(guideView)

            guideViewLabel.attributedText = addTipEmojiToGuide(guideText)
            // Setting this here appears to help with updating the layout
            guideViewLabel.lineBreakMode = .byWordWrapping
            invalidateIntrinsicContentSize()

        } else if guideView.superview != nil {
            guideView.removeFromSuperview()
        }
    }

    // Rebuilds guide view for accessibility only if guide view already exists
    private func rebuildGuideViewIfNeeded() {
        /// NSAttributedString initialized with HTML on the background  crashes the app
        /// This method can be called when traitCollectionDidChange which can be triggered when app goes to background
        guard UIApplication.shared.applicationState != .background else {
            return
        }

        if guideText != nil,
           let statsSummaryType = statsSummaryType,
           let guideText = StatsTotalInsightsData.makeTotalInsightsGuideText(lastPostInsight: lastPostInsight, statsSummaryType: statsSummaryType) {
            self.guideText = guideText
            updateGuideView(withGuideText: guideText)
        }
    }

    private func updateComparisonLabel(withCount count: Int, difference: Int?, percentage: Int?) {
        guard let difference = difference,
              let percentage = percentage,
              difference != 0 || count > 0 else {
            comparisonLabel.isHidden = true
            return
        }

        comparisonLabel.isHidden = false
        let differencePrefix = difference < 0 ? "" : "+"

        let differenceText: String = {
            if difference > 0 {
                return String(format: TextContent.differenceHigher, differencePrefix, difference.abbreviatedString(), percentage.abbreviatedString())
            } else if difference < 0 {
                return String(format: TextContent.differenceLower, differencePrefix, difference.abbreviatedString(), percentage.abbreviatedString())
            } else {
                return TextContent.differenceSame
            }
        }()

        comparisonLabel.attributedText = attributedDifferenceString(differenceText, highlightAttributes: [.foregroundColor: differenceTextColor(for: difference)])
    }

    private func addTipEmojiToGuide(_ guideText: NSAttributedString) -> NSAttributedString {
        let result: NSMutableAttributedString

        switch effectiveUserInterfaceLayoutDirection {
        case .leftToRight:
            result = NSMutableAttributedString(string: "💡 ")
            result.append(guideText)
        case .rightToLeft:
            result = NSMutableAttributedString(attributedString: guideText)
            result.append(NSAttributedString(string: " 💡"))
        @unknown default:
            return guideText
        }

        return result
    }

    private func differenceTextColor(for difference: Int) -> UIColor {
        return difference < 0 ? WPStyleGuide.Stats.negativeColor : WPStyleGuide.Stats.positiveColor
    }

    private func chartColor(for difference: Int) -> UIColor {
        return difference < 0 ? WPStyleGuide.Stats.neutralColor : WPStyleGuide.Stats.positiveColor
    }

    private func attributedDifferenceString(_ string: String, highlightAttributes: [NSAttributedString.Key: Any]) -> NSAttributedString {
        let defaultAttributes = [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .subheadline), NSAttributedString.Key.foregroundColor: UIColor.textSubtle]

        guard let range = StatsTotalInsightsCell.rangeOfDifferenceSubstring(string) else {
            return NSAttributedString(string: string, attributes: defaultAttributes)
        }

        let string = string.replacingOccurrences(of: String(TextContent.differenceDelimiter), with: "")
        let nsRange = NSRange(range, in: string)

        let mutableString = NSMutableAttributedString(string: string, attributes: defaultAttributes)
        mutableString.addAttributes(highlightAttributes, range: nsRange)

        return NSAttributedString(attributedString: mutableString)
    }

    static func rangeOfDifferenceSubstring(_ string: String) -> Range<String.Index>? {
        guard let firstIndex = string.firstIndex(of: TextContent.differenceDelimiter),
              let lastIndex = string.lastIndex(of: TextContent.differenceDelimiter),
              firstIndex != lastIndex else {
            return nil
        }

        let range: Range<String.Index> = firstIndex..<string.index(lastIndex, offsetBy: -1)

        return range
    }

    @objc private func guideTapped() {
        if let guideURL = guideURL {
            siteStatsInsightsDelegate?.displayWebViewWithURL?(guideURL)
        }

        guard let statSection = statSection else {
            return
        }

        switch statSection {
        case .insightsLikesTotals:
            captureAnalyticsEvent(.statsInsightsTotalLikesGuideTapped)
        default:
            break
        }
    }

    private func captureAnalyticsEvent(_ event: WPAnalyticsEvent) {
        WPAnalytics.track(event)
    }

    private enum Metrics {
        static let outerStackViewSpacing: CGFloat = 16.0
        static let stackViewSpacing: CGFloat = 8.0
        static let graphViewAspectRatio: CGFloat = 3.27
    }

    private enum TextContent {
        static let differenceDelimiter = Character("*")
        static let differenceHigher = NSLocalizedString("stats.insights.label.totalLikes.higher",
                                                        value: "*%@%@ (%@%%)* higher than the previous 7-days",
                                                        comment: "Label shown on some metrics in the Stats Insights section, such as Comments count. The placeholders will be populated with a change and a percentage – e.g. '+17 (40%) higher than the previous 7-days'. The *s mark the numerical values, which will be highlighted differently from the rest of the text.")
        static let differenceLower = NSLocalizedString("stats.insights.label.totalLikes.lower",
                                                       value: "*%@%@ (%@%%)* lower than the previous 7-days",
                                                       comment: "Label shown on some metrics in the Stats Insights section, such as Comments count. The placeholders will be populated with a change and a percentage – e.g. '-17 (40%) lower than the previous 7-days'. The *s mark the numerical values, which will be highlighted differently from the rest of the text.")
        static let differenceSame = NSLocalizedString("stats.insights.label.totalLikes.same",
                                                      value: "The same as the previous 7-days",
                                                      comment: "Label shown in Stats Insights when a metric is showing the same level as the previous 7 days")
    }
}
