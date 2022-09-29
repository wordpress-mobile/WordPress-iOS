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

    public static func createTotalInsightsData(periodStore: StatsPeriodStore, insightsStore: StatsInsightsStore, statsSummaryType: StatsSummaryType, guideText: NSAttributedString? = nil) -> StatsTotalInsightsData {
        guard let periodSummary = periodStore.getSummary() else {
            return StatsTotalInsightsData(count: 0)
        }

        let splitSummaryTimeIntervalData = SiteStatsInsightsViewModel.splitStatsSummaryTimeIntervalData(periodSummary)

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
        let data = SiteStatsInsightsViewModel.intervalData(periodSummary, summaryType: statsSummaryType)
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

    public static func makeTotalInsightsGuideText(lastPostInsight: StatsLastPostInsight?, statsSummaryType: StatsSummaryType) -> NSAttributedString? {
        switch statsSummaryType {
        case .likes:
            guard let summary = lastPostInsight else {
                return nil
            }

            let formattedText: String
            if summary.likesCount == Constants.singularLikeCount {
                formattedText = String(format: TextContent.likesTotalGuideTextSingular, summary.title)
            } else {
                formattedText = String(format: TextContent.likesTotalGuideTextPlural, summary.title, summary.likesCount)
            }

            return NSAttributedString.attributedStringWithHTML(formattedText, attributes: StatsTotalInsightsData.guideAttributes)
        case .comments:
            return NSAttributedString(string: TextContent.commentsTotalGuideText)
        default:
            return nil
        }
    }

    private static var guideAttributes: StyledHTMLAttributes = [
        .BodyAttribute: [
            .font: UIFont.preferredFont(forTextStyle: .subheadline),
            .foregroundColor: UIColor.text
        ],
        .ATagAttribute: [
            .foregroundColor: UIColor.primary,
            .underlineStyle: 0
        ]
    ]

    private enum Constants {
        static let singularLikeCount = 1
    }

    private enum TextContent {
        static let likesTotalGuideTextSingular = NSLocalizedString("Your latest post <a href=\"\">%@</a> has received <strong>one</strong> like.", comment: "A hint shown to the user in stats informing the user that one of their posts has received a like. The %@ placeholder will be replaced with the title of a post, and the HTML tags should remain intact.")
        static let likesTotalGuideTextPlural = NSLocalizedString("Your latest post <a href=\"\">%@</a> has received <strong>%d</strong> likes.", comment: "A hint shown to the user in stats informing the user how many likes one of their posts has received. The %@ placeholder will be replaced with the title of a post, the %d with the number of likes, and the HTML tags should remain intact.")
        static let commentsTotalGuideText = NSLocalizedString("Tap \"Week\" to see your top commenters.", comment: "A hint shown to the user in stats telling them how to navigate to the Comments detail view.")
    }
}

class StatsTotalInsightsCell: StatsBaseCell {
    private weak var siteStatsInsightsDelegate: SiteStatsInsightsDelegate?
    private var lastPostInsight: StatsLastPostInsight?
    private var statsSummaryType: StatsSummaryType?
    private var guideURL: URL? = nil

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

        updateGuideView()
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
            topConstraint,
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
        self.siteStatsInsightsDelegate = siteStatsInsightsDelegate
        self.siteStatsInsightDetailsDelegate = siteStatsInsightsDelegate

        graphView.data = dataRow.sparklineData ?? []
        graphView.chartColor = chartColor(for: dataRow.difference ?? 0)

        countLabel.text = dataRow.count.abbreviatedString()

        updateGuideView()
        updateComparisonLabel(withCount: dataRow.count, difference: dataRow.difference, percentage: dataRow.percentage)
    }

    private func updateGuideView() {
        if let statsSummaryType = statsSummaryType,
           let guideText = StatsTotalInsightsData.makeTotalInsightsGuideText(lastPostInsight: lastPostInsight, statsSummaryType: statsSummaryType),
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

        guard let firstIndex = string.firstIndex(of: TextContent.differenceDelimiter),
              let lastIndex = string.lastIndex(of: TextContent.differenceDelimiter),
              firstIndex != lastIndex else {
                  return NSAttributedString(string: string, attributes: defaultAttributes)
              }

        let string = string.replacingOccurrences(of: String(TextContent.differenceDelimiter), with: "")

        // Move the end of the range back by one as we've removed a character
        let range: Range<String.Index> = firstIndex..<string.index(lastIndex, offsetBy: -1)
        let nsRange = NSRange(range, in: string)

        let mutableString = NSMutableAttributedString(string: string, attributes: defaultAttributes)
        mutableString.addAttributes(highlightAttributes, range: nsRange)

        return NSAttributedString(attributedString: mutableString)
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
        static let differenceHigher = NSLocalizedString("*%@%@ (%@%%)* higher than the previous week", comment: "Label shown on some metrics in the Stats Insights section, such as Comments count. The placeholders will be populated with a change and a percentage – e.g. '+17 (40%) higher than the previous week'. The *s mark the numerical values, which will be highlighted differently from the rest of the text.")
        static let differenceLower = NSLocalizedString("*%@%@ (%@%%)* lower than the previous week", comment: "Label shown on some metrics in the Stats Insights section, such as Comments count. The placeholders will be populated with a change and a percentage – e.g. '-17 (40%) lower than the previous week'. The *s mark the numerical values, which will be highlighted differently from the rest of the text.")
        static let differenceSame = NSLocalizedString("The same as the previous week", comment: "Label shown in Stats Insights when a metric is showing the same level as the previous week")
    }
}
