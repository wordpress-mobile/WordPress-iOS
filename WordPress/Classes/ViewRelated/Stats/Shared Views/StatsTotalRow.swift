import UIKit

struct StatsTotalRowData {
    var name: String
    var data: String
    var mediaID: NSNumber?
    var postID: Int?
    var dataBarPercent: Float?
    var icon: UIImage?
    var socialIconURL: URL?
    var userIconURL: URL?
    var nameDetail: String?
    var showDisclosure: Bool
    var disclosureURL: URL?
    var childRows: [StatsTotalRowData]?
    var statSection: StatSection?

    init(name: String,
         data: String,
         mediaID: NSNumber? = nil,
         postID: Int? = nil,
         dataBarPercent: Float? = nil,
         icon: UIImage? = nil,
         socialIconURL: URL? = nil,
         userIconURL: URL? = nil,
         nameDetail: String? = nil,
         showDisclosure: Bool = false,
         disclosureURL: URL? = nil,
         childRows: [StatsTotalRowData]? = [StatsTotalRowData](),
         statSection: StatSection? = nil) {
        self.name = name
        self.data = data
        self.mediaID = mediaID
        self.postID = postID
        self.dataBarPercent = dataBarPercent
        self.nameDetail = nameDetail
        self.icon = icon
        self.socialIconURL = socialIconURL
        self.userIconURL = userIconURL
        self.showDisclosure = showDisclosure
        self.disclosureURL = disclosureURL
        self.childRows = childRows
        self.statSection = statSection
    }

    var hasIcon: Bool {
        return self.icon != nil || self.socialIconURL != nil || self.userIconURL != nil
    }
}

@objc protocol StatsTotalRowDelegate {
    @objc optional func displayWebViewWithURL(_ url: URL)
    @objc optional func displayMediaWithID(_ mediaID: NSNumber)
    @objc optional func toggleChildRows(for row: StatsTotalRow, didSelectRow: Bool)
    @objc optional func showPostStats(postID: Int, postTitle: String?, postURL: URL?)
    @objc optional func showAddInsight()
}

class StatsTotalRow: UIView, NibLoadable, Accessible {

    // MARK: - Properties

    @IBOutlet weak var contentView: UIView!

    // The default line shown indented at the bottom of the view. Shown by default.
    @IBOutlet weak var separatorLine: UIView!

    // Line shown at the top of the view, spanning the entire width.
    // It is shown when a row is selected that can expand, used to indicate
    // the top of the expanded rows section. Hidden by default.
    @IBOutlet weak var topExpandedSeparatorLine: UIView!

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var imageWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageHeightConstraint: NSLayoutConstraint!

    @IBOutlet weak var itemLabel: UILabel!
    @IBOutlet weak var itemDetailLabel: UILabel!

    @IBOutlet weak var leftStackView: UIStackView!
    @IBOutlet weak var dataBarView: UIView!
    @IBOutlet weak var dataBar: UIView!
    @IBOutlet weak var dataBarWidthConstraint: NSLayoutConstraint!

    @IBOutlet weak var rightStackViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var rightStackView: UIStackView!
    @IBOutlet weak var dataLabel: UILabel!
    @IBOutlet weak var disclosureImageView: UIImageView!
    @IBOutlet weak var disclosureButton: UIButton!

    private(set) var rowData: StatsTotalRowData?
    private var dataBarMaxTrailing: Float = 0.0
    private typealias Style = WPStyleGuide.Stats
    private weak var delegate: StatsTotalRowDelegate?
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
            !childRows.isEmpty {
            return true
        }
        return false
    }

    var expanded: Bool = false {
        didSet {
            guard hasChildRows else {
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
        return rowData?.hasIcon ?? false
    }

    // MARK: - Configure

    func configure(rowData: StatsTotalRowData,
                   delegate: StatsTotalRowDelegate? = nil,
                   forDetails: Bool = false,
                   parentRow: StatsTotalRow? = nil) {
        self.rowData = rowData
        self.delegate = delegate
        self.forDetails = forDetails
        self.parentRow = parentRow

        configureIcon()
        configureExpandedState()
        configureDetailDisclosure()

        // Set values
        itemLabel.text = rowData.name
        itemDetailLabel.text = rowData.nameDetail
        dataLabel.text = rowData.data

        // Toggle optionals
        configureDisclosureButton()
        disclosureImageView.isHidden = !rowData.showDisclosure
        itemDetailLabel.isHidden = (rowData.nameDetail == nil)
        dataBarView.isHidden = (rowData.dataBarPercent == nil)
        separatorLine.isHidden = !showSeparator
        dataLabel.isHidden = rowData.data.isEmpty

        applyStyles()
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
        accessibilityLabel = [itemTitle, dataTitle].joined(separator: ", ")

        if let statSection = rowData?.statSection, statSection == .insightsAddInsight {
            accessibilityTraits = .button
            accessibilityHint = NSLocalizedString("Tap to customize insights", comment: "Accessibility hint")
            return
        }

        let showDisclosure = rowData?.showDisclosure ?? false
        accessibilityTraits = (showDisclosure) ? .button : .staticText
        accessibilityHint = (showDisclosure) ? NSLocalizedString("Tap for more detail.", comment: "Accessibility hint") : ""

        switch (showDisclosure, hasChildRows) {
        case (true, true):
            accessibilityHint = expanded
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

    func applyStyles() {
        backgroundColor = .listForeground
        contentView.backgroundColor = .listForeground
        Style.configureLabelAsCellRowTitle(itemLabel)
        Style.configureLabelItemDetail(itemDetailLabel)
        Style.configureLabelAsData(dataLabel)
        Style.configureViewAsSeparator(separatorLine)
        Style.configureViewAsSeparator(topExpandedSeparatorLine)
        Style.configureViewAsDataBar(dataBar)
    }

    func configureDisclosureButton() {
        guard let rowData = rowData else {
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
        guard hasChildRows, forDetails else {
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
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: { [weak self] in
            self?.disclosureImageView.transform = CGAffineTransform(rotationAngle: self?.disclosureRotation() ?? 0)
        })
    }

    func disclosureRotation() -> CGFloat {
        return expanded ? (Constants.disclosureImageUp) : (Constants.disclosureImageDown)
    }

    func configureIcon() {

        guard let rowData = rowData else {
            return
        }

        let imageSize = rowData.statSection?.imageSize ?? StatSection.defaultImageSize

        // If the parent row has an icon and this row does not,
        // show the image view to make this row appear "indented" by the icon width.
        if let parentRow = parentRow, parentRow.hasIcon, !hasIcon {
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
        WPImageSource.shared()?.downloadImage(for: iconURL, withSuccess: { image in
            self.imageView.image = image
            self.imageView.backgroundColor = .clear
        }, failure: { error in
            DDLogInfo("Error downloading image: \(String(describing: error?.localizedDescription)). From URL: \(iconURL).")
            self.imageView.isHidden = true
        })
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

    @IBAction func didTapDisclosureButton(_ sender: UIButton) {

        if let statSection = rowData?.statSection {
            captureAnalyticsEventsFor(statSection)
        }

        if let mediaID = rowData?.mediaID {
            delegate?.displayMediaWithID?(mediaID)
            return
        }

        if hasChildRows {
            expanded.toggle()
            prepareForVoiceOver()
            delegate?.toggleChildRows?(for: self, didSelectRow: true)
            return
        }

        if let disclosureURL = rowData?.disclosureURL {
            if let statSection = rowData?.statSection,
                statSection == .periodPostsAndPages {
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

    func captureAnalyticsEventsFor(_ statSection: StatSection) {
        guard let event = statSection.analyticsItemTappedEvent else {
            return
        }

        if let blogIdentifier = SiteStatsInformation.sharedInstance.siteID {
            WPAppAnalytics.track(event, withBlogID: blogIdentifier)
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
        default:
            return nil
        }
    }
}
