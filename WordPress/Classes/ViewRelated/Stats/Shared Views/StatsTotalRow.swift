import UIKit
import AsyncImageKit
import WordPressShared

struct StatsTotalRowData: Equatable {
    var id: UUID?
    var name: String
    var data: String
    var secondData: String?
    var mediaID: NSNumber?
    var postID: Int?
    var dataBarPercent: Float?
    var icon: UIImage?
    var socialIconURL: URL?
    var userIconURL: URL?
    var nameDetail: String?
    var showDisclosure: Bool
    var disclosureURL: URL?
    var multiline: Bool
    var childRows: [StatsTotalRowData]?
    var statSection: StatSection?
    var isReferrerSpam: Bool

    init(
        id: UUID? = nil,
        name: String,
        data: String,
        secondData: String? = nil,
        mediaID: NSNumber? = nil,
        postID: Int? = nil,
        dataBarPercent: Float? = nil,
        icon: UIImage? = nil,
        socialIconURL: URL? = nil,
        userIconURL: URL? = nil,
        nameDetail: String? = nil,
        showDisclosure: Bool = false,
        disclosureURL: URL? = nil,
        multiline: Bool = true,
        childRows: [StatsTotalRowData]? = [StatsTotalRowData](),
        statSection: StatSection? = nil,
        isReferrerSpam: Bool = false
    ) {
        self.id = id
        self.name = name
        self.data = data
        self.secondData = secondData
        self.mediaID = mediaID
        self.postID = postID
        self.dataBarPercent = dataBarPercent
        self.nameDetail = nameDetail
        self.icon = icon
        self.socialIconURL = socialIconURL
        self.userIconURL = userIconURL
        self.showDisclosure = showDisclosure
        self.disclosureURL = disclosureURL
        self.multiline = multiline
        self.childRows = childRows
        self.statSection = statSection
        self.isReferrerSpam = isReferrerSpam
    }

    var hasIcon: Bool {
        self.icon != nil || self.socialIconURL != nil || self.userIconURL != nil
    }

    static func flagImage(for countryCode: String) -> UIImage? {
        let base: UInt32 = 127397
        var scalarView = String.UnicodeScalarView()
        for scalar in countryCode.uppercased().unicodeScalars {
            guard let flagScalar = UnicodeScalar(base + scalar.value) else { return nil }
            scalarView.append(flagScalar)
        }
        let emoji = String(scalarView)
        let size = CGSize(width: 24, height: 24)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 18)
            ]
            let textSize = emoji.size(withAttributes: attributes)
            let origin = CGPoint(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2
            )
            emoji.draw(at: origin, withAttributes: attributes)
        }
    }

    var canMarkReferrerAsSpam: Bool {
        if let url = disclosureURL {
            return url.absoluteString.contains(name)
        } else {
            return name.contains(".")
        }
    }

    static func == (lhs: StatsTotalRowData, rhs: StatsTotalRowData) -> Bool {
        lhs.id == rhs.id && lhs.name == rhs.name && lhs.data == rhs.data && lhs.mediaID == rhs.mediaID
            && lhs.postID == rhs.postID && lhs.dataBarPercent == rhs.dataBarPercent
            && lhs.socialIconURL?.absoluteString == rhs.socialIconURL?.absoluteString
            && lhs.userIconURL == rhs.userIconURL && lhs.nameDetail == rhs.nameDetail
            && lhs.showDisclosure == rhs.showDisclosure
            && lhs.disclosureURL?.absoluteString == rhs.disclosureURL?.absoluteString && lhs.childRows == rhs.childRows
            && lhs.statSection == rhs.statSection && lhs.isReferrerSpam == rhs.isReferrerSpam
    }
}

@objc protocol StatsTotalRowDelegate {
    @objc optional func displayWebViewWithURL(_ url: URL)
    @objc optional func displayMediaWithID(_ mediaID: NSNumber)
    @objc optional func toggleChildRows(for row: StatsTotalRow, didSelectRow: Bool)
    @objc optional func showPostStats(postID: Int, postTitle: String?, postURL: URL?)
    @objc optional func showAddInsight()
}

protocol StatsTotalRowReferrerDelegate: AnyObject {
    func showReferrerDetails(_ data: StatsTotalRowData)
}

class StatsTotalRow: UIView, Accessible {

    // MARK: - Properties

    let contentView = UIView()

    // The default line shown indented at the bottom of the view. Shown by default.
    let separatorLine = makeSeparator()

    // Line shown at the top of the view, spanning the entire width.
    // It is shown when a row is selected that can expand, used to indicate
    // the top of the expanded rows section. Hidden by default.
    let topExpandedSeparatorLine: UIView = {
        let view = makeSeparator()
        view.isHidden = true
        return view
    }()

    let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.isHidden = true
        imageView.setContentHuggingPriority(UILayoutPriority(251), for: .horizontal)
        imageView.setContentHuggingPriority(UILayoutPriority(251), for: .vertical)
        return imageView
    }()
    private(set) var imageWidthConstraint: NSLayoutConstraint!
    private(set) var imageHeightConstraint: NSLayoutConstraint!

    let itemLabel = makeItemLabel(text: "Item Label", textStyle: .body)
    let itemDetailLabel = makeItemLabel(text: "Item Detail Label", textStyle: .subheadline)

    let leftStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.alignment = .center
        stackView.spacing = 16
        return stackView
    }()
    let dataBarView: UIView = {
        let view = UIView()
        view.isHidden = true
        view.backgroundColor = .clear
        return view
    }()
    let dataBar: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(white: 0.667, alpha: 1)
        return view
    }()
    private(set) var dataBarWidthConstraint: NSLayoutConstraint!

    private(set) var rightStackViewLeadingConstraint: NSLayoutConstraint!
    let rightStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.alignment = .center
        stackView.spacing = 16
        return stackView
    }()
    let dataLabel = makeDataLabel()
    /// Deactivated (and released) once a row shows `secondDataLabel`.
    private(set) weak var dataLabelWidthConstraint: NSLayoutConstraint?
    let secondDataLabel: UILabel = {
        let label = makeDataLabel()
        label.isHidden = true
        return label
    }()
    let disclosureImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "chevron.forward"))
        imageView.isHidden = true
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .secondaryLabel
        imageView.setContentHuggingPriority(UILayoutPriority(251), for: .horizontal)
        imageView.setContentHuggingPriority(UILayoutPriority(251), for: .vertical)
        return imageView
    }()
    let disclosureButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .clear
        return button
    }()

    private(set) var rowData: StatsTotalRowData?
    private typealias Style = WPStyleGuide.Stats
    private weak var delegate: StatsTotalRowDelegate?
    private weak var referrerDelegate: StatsTotalRowReferrerDelegate?
    private var forDetails = false
    private(set) weak var parentRow: StatsTotalRow?

    // This view is modified by the containing cell, to show/hide
    // child rows when a parent row is selected.
    weak var childRowsView: StatsChildRowsView?

    var showSeparator = true {
        didSet {
            separatorLine.isHidden = !showSeparator
        }
    }

    var showTopExpandedSeparator = false {
        didSet {
            topExpandedSeparatorLine.isHidden = !showTopExpandedSeparator
        }
    }

    var hasChildRows: Bool {
        if let childRows = rowData?.childRows,
            !childRows.isEmpty
        {
            return true
        }
        return false
    }

    var expanded: Bool = false {
        didSet {
            guard hasChildRows, rowData?.statSection != .periodReferrers else {
                return
            }

            // Don't show row separator on child rows.
            showSeparator = (parentRow != nil) ? false : !expanded
            showTopExpandedSeparator = expanded

            // Detail rows are updated differently,
            // so those disclosure icons are updated on configure.
            if !forDetails {
                rotateDisclosure()
            }
        }
    }

    var hasIcon: Bool {
        rowData?.hasIcon ?? false
    }

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        applyStatsXibRootDefaults(
            size: CGSize(width: 442, height: 80),
            mask: [.flexibleRightMargin, .flexibleBottomMargin]
        )

        backgroundColor = .white
        setUpViews()

        // `configureDataBar()` reads these frames before the first layout pass completes,
        // and `WPStyleGuide.Stats.configureViewAsDataBar` derives the bar's corner radius
        // from its height, so start with the sizes the views had in the original xib.
        contentView.frame = CGRect(x: 16, y: 31, width: 410, height: 38.5)
        rightStackView.frame = CGRect(x: 354, y: 0, width: 56, height: 38.5)
        imageView.frame = CGRect(x: 0, y: 5.5, width: 28, height: 28)
        dataBar.frame = CGRect(x: 0, y: 6, width: 338, height: 5)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUpViews() {
        let labelStackView = UIStackView(arrangedSubviews: [itemLabel, itemDetailLabel, dataBarView])
        labelStackView.axis = .vertical
        labelStackView.alignment = .top
        dataBarView.addSubview(dataBar)

        leftStackView.addArrangedSubview(imageView)
        leftStackView.addArrangedSubview(labelStackView)
        [dataLabel, secondDataLabel, disclosureImageView].forEach(rightStackView.addArrangedSubview)

        [leftStackView, rightStackView]
            .forEach {
                $0.translatesAutoresizingMaskIntoConstraints = false
                contentView.addSubview($0)
            }
        contentView.translatesAutoresizingMaskIntoConstraints = false
        disclosureButton.addTarget(self, action: #selector(didTapDisclosureButton), for: .touchUpInside)
        [contentView, disclosureButton, separatorLine, topExpandedSeparatorLine].forEach(addSubview)

        imageWidthConstraint = imageView.widthAnchor.constraint(equalToConstant: 28)
        imageHeightConstraint = imageView.heightAnchor.constraint(equalToConstant: 28)
        dataBarWidthConstraint = dataBarView.widthAnchor.constraint(equalTo: dataBar.widthAnchor)
        dataBarWidthConstraint.priority = UILayoutPriority(999)
        rightStackViewLeadingConstraint = rightStackView.leadingAnchor.constraint(
            equalTo: leftStackView.trailingAnchor,
            constant: 16
        )
        let dataLabelWidthConstraint = dataLabel.widthAnchor.constraint(equalToConstant: 56)
        self.dataLabelWidthConstraint = dataLabelWidthConstraint

        let guide = safeAreaLayoutGuide
        let contentBottomConstraint = guide.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 11)
        contentBottomConstraint.priority = UILayoutPriority(999)

        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: guide.topAnchor, constant: 11),
            contentView.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 16),
            guide.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 16),
            contentBottomConstraint,
            contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 22),

            leftStackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            leftStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            leftStackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            leftStackView.centerYAnchor.constraint(equalTo: rightStackView.centerYAnchor),
            rightStackViewLeadingConstraint,
            rightStackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            contentView.trailingAnchor.constraint(equalTo: rightStackView.trailingAnchor),

            imageWidthConstraint,
            imageHeightConstraint,
            labelStackView.trailingAnchor.constraint(equalTo: dataBarView.trailingAnchor),

            dataBar.topAnchor.constraint(equalTo: dataBarView.topAnchor, constant: 6),
            dataBar.leadingAnchor.constraint(equalTo: dataBarView.leadingAnchor),
            dataBarView.bottomAnchor.constraint(equalTo: dataBar.bottomAnchor),
            dataBar.heightAnchor.constraint(equalToConstant: 5),
            dataBarWidthConstraint,

            dataLabelWidthConstraint,
            secondDataLabel.widthAnchor.constraint(equalToConstant: 56),
            disclosureImageView.widthAnchor.constraint(equalToConstant: 9),
            disclosureImageView.heightAnchor.constraint(equalToConstant: 15),

            disclosureButton.topAnchor.constraint(equalTo: guide.topAnchor),
            disclosureButton.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            guide.trailingAnchor.constraint(equalTo: disclosureButton.trailingAnchor),

            separatorLine.topAnchor.constraint(equalTo: disclosureButton.bottomAnchor),
            separatorLine.leadingAnchor.constraint(equalTo: labelStackView.leadingAnchor),
            guide.trailingAnchor.constraint(equalTo: separatorLine.trailingAnchor),
            guide.bottomAnchor.constraint(equalTo: separatorLine.bottomAnchor),

            topExpandedSeparatorLine.topAnchor.constraint(equalTo: guide.topAnchor),
            topExpandedSeparatorLine.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            guide.trailingAnchor.constraint(equalTo: topExpandedSeparatorLine.trailingAnchor)
        ])
    }

    private static func makeSeparator() -> UIView {
        let view = UIView.makeStatsSeparator()
        view.backgroundColor = UIColor(white: 0.667, alpha: 1)
        return view
    }

    private static func makeItemLabel(text: String, textStyle: UIFont.TextStyle) -> UILabel {
        let label = UILabel.makeStatsLabel(text: text, textStyle: textStyle)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        return label
    }

    private static func makeDataLabel() -> UILabel {
        UILabel.makeStatsLabel(text: "999", textStyle: .body, textAlignment: .right)
    }

    // MARK: - Configure

    func configure(
        rowData: StatsTotalRowData,
        delegate: StatsTotalRowDelegate? = nil,
        referrerDelegate: StatsTotalRowReferrerDelegate? = nil,
        forDetails: Bool = false,
        parentRow: StatsTotalRow? = nil
    ) {
        self.rowData = rowData
        self.delegate = delegate
        self.referrerDelegate = referrerDelegate
        self.forDetails = forDetails
        self.parentRow = parentRow

        configureIcon()
        configureExpandedState()
        configureDetailDisclosure()

        // Set values
        itemLabel.text = rowData.name
        itemDetailLabel.text = rowData.nameDetail
        dataLabel.text = rowData.data
        secondDataLabel.text = rowData.secondData

        // Toggle optionals
        configureDisclosureButton()
        disclosureImageView.isHidden = !rowData.showDisclosure
        itemDetailLabel.isHidden = (rowData.nameDetail == nil)
        dataBarView.isHidden = (rowData.dataBarPercent == nil)
        separatorLine.isHidden = !showSeparator
        dataLabel.isHidden = rowData.data.isEmpty
        secondDataLabel.isHidden = (rowData.secondData ?? "").isEmpty
        dataLabelWidthConstraint?.isActive = !secondDataLabel.isHidden

        applyStyles(rowData)
        prepareForVoiceOver()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        configureDataBar()
    }

    // MARK: - Accessibility

    func prepareForVoiceOver() {
        isAccessibilityElement = true

        let itemTitle = itemLabel.text ?? ""
        let dataTitle = dataLabel.text ?? ""
        let secondDataTitle = secondDataLabel.text

        accessibilityLabel = [itemTitle, dataTitle, secondDataTitle].compactMap { $0 }.joined(separator: ", ")

        if let statSection = rowData?.statSection, statSection == .insightsAddInsight {
            accessibilityTraits = .button
            accessibilityHint = NSLocalizedString("Tap to customize insights", comment: "Accessibility hint")
            return
        }

        let showDisclosure = rowData?.showDisclosure ?? false
        accessibilityTraits = (showDisclosure) ? .button : .staticText
        accessibilityHint =
            (showDisclosure) ? NSLocalizedString("Tap for more detail.", comment: "Accessibility hint") : ""

        switch (showDisclosure, hasChildRows) {
        case (true, true):
            accessibilityHint =
                expanded
                ? NSLocalizedString("Expanded. Tap to collapse.", comment: "Accessibility hint")
                : NSLocalizedString("Collapsed. Tap to expand.", comment: "Accessibility hint")
        case (true, false):
            accessibilityHint = NSLocalizedString("Tap for more detail.", comment: "Accessibility hint")
        default:
            break
        }
    }
}

private extension StatsTotalRow {

    func applyStyles(_ rowData: StatsTotalRowData) {
        backgroundColor = .secondarySystemGroupedBackground
        contentView.backgroundColor = .secondarySystemGroupedBackground
        Style.configureLabelAsCellRowTitle(itemLabel)
        Style.configureLabelItemDetail(itemDetailLabel)
        Style.configureLabelAsData(dataLabel)
        Style.configureLabelAsData(secondDataLabel)
        Style.configureViewAsSeparator(separatorLine)
        Style.configureViewAsSeparator(topExpandedSeparatorLine)
        Style.configureViewAsDataBar(dataBar)

        [itemLabel, itemDetailLabel, dataLabel, secondDataLabel]
            .forEach {
                $0.adjustsFontForContentSizeCategory = true
                $0.maximumContentSizeCategory = .extraExtraLarge
            }

        [itemLabel, itemDetailLabel]
            .forEach {
                $0.numberOfLines = rowData.multiline ? 0 : 1
            }
    }

    func configureDisclosureButton() {
        guard let rowData else {
            disclosureButton.isEnabled = false
            return
        }

        disclosureButton.isEnabled = rowData.showDisclosure

        // Add Insight doesn't have a disclosure icon, but it needs a tap action.
        if rowData.statSection == .insightsAddInsight {
            disclosureButton.isEnabled = true
        }
    }

    func configureExpandedState() {
        guard let name = rowData?.name, let statSection = rowData?.statSection else {
            expanded = false
            return
        }

        let expandedLabels = forDetails ? StatsDataHelper.expandedRowLabelsDetails : StatsDataHelper.expandedRowLabels
        expanded = expandedLabels[statSection]?.contains(name) ?? false
    }

    func configureDetailDisclosure() {
        guard hasChildRows, forDetails, rowData?.statSection != .periodReferrers else {
            return
        }

        // If the detail row has been expanded/collapsed, animate the icon rotation.
        // Otherwise, just set the rotation.

        if StatsDataHelper.detailRowDisclosureNeedsUpdating == rowData?.name {
            StatsDataHelper.detailRowDisclosureNeedsUpdating = nil
            rotateDisclosure()
        } else {
            disclosureImageView.transform = CGAffineTransform(rotationAngle: disclosureRotation())
        }
    }

    func rotateDisclosure() {
        UIView.animate(
            withDuration: 0.3,
            delay: 0,
            options: .curveEaseOut,
            animations: { [weak self] in
                self?.disclosureImageView.transform = CGAffineTransform(rotationAngle: self?.disclosureRotation() ?? 0)
            }
        )
    }

    func disclosureRotation() -> CGFloat {
        expanded ? (Constants.disclosureImageUp) : (Constants.disclosureImageDown)
    }

    func configureIcon() {
        guard let rowData else {
            return
        }

        let imageSize = rowData.statSection?.imageSize ?? StatSection.defaultImageSize

        // If the parent row has an icon and this row does not,
        // show the image view to make this row appear "indented" by the icon width.
        if let parentRow, parentRow.hasIcon, !hasIcon {
            imageView.isHidden = false
            imageWidthConstraint.constant = parentRow.imageWidthConstraint.constant
            imageHeightConstraint.constant = 1
        } else {
            imageView.isHidden = !hasIcon
            imageWidthConstraint.constant = imageSize
            imageHeightConstraint.constant = imageSize
        }

        if let icon = rowData.icon {
            imageView.image = icon
        }

        if let iconURL = rowData.socialIconURL {
            // Show a grey box with rounded corners until image is loaded.
            imageView.backgroundColor = Style.iconLoadingBackgroundColor
            imageView.layer.cornerRadius = 4.0
            downloadImageFrom(iconURL)
        }

        if let iconURL = rowData.userIconURL {
            // Show user icon as a circle.
            imageView.layer.cornerRadius = imageSize * 0.5
            imageView.clipsToBounds = true

            // Use placeholder image until image is loaded.
            imageView.image = Style.gravatarPlaceholderImage()

            downloadImageFrom(iconURL)
        }
    }

    func downloadImageFrom(_ iconURL: URL) {
        Task { @MainActor [weak self] in
            do {
                let image = try await ImageDownloader.shared.image(from: iconURL)
                self?.imageView.image = image
                self?.imageView.backgroundColor = .clear
            } catch {
                DDLogInfo("Error downloading image: \(error.localizedDescription). From URL: \(iconURL).")
                self?.imageView.isHidden = true
            }
        }
    }

    func configureDataBar() {
        guard let dataBarPercent = rowData?.dataBarPercent else {
            dataBarView.isHidden = true
            return
        }

        dataBarView.isHidden = false

        // Calculate the max bar width.
        // Calculate the bar width.
        // Determine the distance from the bar to the max width.
        // Set that distance as the bar width.

        let dataWidth = rightStackView.frame.width + rightStackViewLeadingConstraint.constant + rightStackView.spacing
        var maxBarWidth = Float(contentView.frame.width - dataWidth)

        if !imageView.isHidden {
            let imageWidth = imageView.frame.width + leftStackView.spacing
            maxBarWidth -= Float(imageWidth)
        }

        let barWidth = maxBarWidth * dataBarPercent
        let distanceFromMax = maxBarWidth - barWidth
        dataBarWidthConstraint.constant = CGFloat(distanceFromMax)
    }

    struct Constants {
        static let disclosureImageUp = CGFloat.pi * 1.5
        static let disclosureImageDown = CGFloat.pi / 2
    }

    @objc func didTapDisclosureButton(_ sender: UIButton) {
        if let statSection = rowData?.statSection,
            statSection != .insightsAddInsight
        {
            captureAnalyticsEventsFor(statSection)
        }

        if let mediaID = rowData?.mediaID {
            delegate?.displayMediaWithID?(mediaID)
            return
        }

        if rowData?.statSection == .periodReferrers, let data = rowData {
            if !data.canMarkReferrerAsSpam, !hasChildRows, let url = data.disclosureURL {
                delegate?.displayWebViewWithURL?(url)
            } else {
                referrerDelegate?.showReferrerDetails(data)
            }
            return
        }

        if hasChildRows {
            toggleExpandedState()
            return
        }

        if let disclosureURL = rowData?.disclosureURL {
            if let statSection = rowData?.statSection,
                statSection == .periodPostsAndPages || statSection == .periodAuthors
            {
                guard let postID = rowData?.postID else {
                    DDLogInfo("No postID available to show Post Stats.")
                    return
                }
                delegate?.showPostStats?(postID: postID, postTitle: rowData?.name, postURL: rowData?.disclosureURL)
            } else {
                delegate?.displayWebViewWithURL?(disclosureURL)
            }
            return
        }

        if let statSection = rowData?.statSection, statSection == .insightsAddInsight {
            delegate?.showAddInsight?()
            return
        }

        DDLogInfo("Stat row selection action not supported.")
    }

    func toggleExpandedState() {
        expanded.toggle()
        prepareForVoiceOver()
        delegate?.toggleChildRows?(for: self, didSelectRow: true)
    }

    func captureAnalyticsEventsFor(_ statSection: StatSection) {
        guard let event = statSection.analyticsItemTappedEvent else {
            return
        }

        if let blogIdentifier = SiteStatsInformation.sharedInstance.siteID {
            WPAppAnalytics.track(event, blogID: blogIdentifier)
        } else {
            WPAppAnalytics.track(event)
        }
    }
}

// MARK: - Analytics support

private extension StatSection {
    var analyticsItemTappedEvent: WPAnalyticsStat? {
        switch self {
        case .periodAuthors, .insightsCommentsAuthors:
            return .statsItemTappedAuthors
        case .periodClicks:
            return .statsItemTappedClicks
        case .periodPostsAndPages:
            return .statsItemTappedPostsAndPages
        case .periodSearchTerms:
            return .statsItemTappedSearchTerms
        case .insightsTagsAndCategories:
            return .statsItemTappedTagsAndCategories
        case .periodVideos:
            return .statsItemTappedVideoTapped
        case .insightsAddInsight:
            return .statsItemTappedInsightsAddStat
        case .postStatsMonthsYears:
            return .statsItemTappedPostStatsMonthsYears
        case .postStatsRecentWeeks:
            return .statsItemTappedPostStatsRecentWeeks
        default:
            return nil
        }
    }
}
