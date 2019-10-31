import UIKit
import Gridicons

class StatsCellHeader: UITableViewCell, NibLoadable, Accessible {

    // MARK: - Properties

    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var manageInsightButton: UIButton!
    @IBOutlet weak var manageInsightImageView: UIImageView!
    @IBOutlet weak var stackViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var stackViewHeightConstraint: NSLayoutConstraint!

    private typealias Style = WPStyleGuide.Stats
    private var statSection: StatSection?
    private weak var siteStatsInsightsDelegate: SiteStatsInsightsDelegate?
    private var defaultStackViewTopConstraint: CGFloat = 0
    private var defaultStackViewHeightConstraint: CGFloat = 0
    private var adjustHeightForPostStats = false
    private let emptyPostStatsHeight: CGFloat = 20

    // MARK: - Configure

    override func awakeFromNib() {
        defaultStackViewTopConstraint = stackViewTopConstraint.constant
        defaultStackViewHeightConstraint = stackViewHeightConstraint.constant
    }

    func configure(statSection: StatSection? = nil, siteStatsInsightsDelegate: SiteStatsInsightsDelegate? = nil) {
        self.siteStatsInsightsDelegate = siteStatsInsightsDelegate
        self.statSection = statSection
        headerLabel.text = statSection?.title ?? ""
        self.adjustHeightForPostStats = (statSection == .postStatsGraph)
        prepareForVoiceOver()
        applyStyles()
    }

    func prepareForVoiceOver() {
        headerLabel.isAccessibilityElement = (headerLabel.text?.isEmpty == false)
        headerLabel.accessibilityElementsHidden = (headerLabel.text?.isEmpty == true)
        headerLabel.accessibilityLabel = headerLabel.text
        headerLabel.accessibilityTraits = .staticText

        manageInsightImageView.isAccessibilityElement = false
        manageInsightButton.isAccessibilityElement = !manageInsightButton.isHidden
        manageInsightButton.accessibilityElementsHidden = manageInsightButton.isHidden
        manageInsightButton.accessibilityTraits = .button
        manageInsightButton.accessibilityLabel = NSLocalizedString("Manage Insight", comment: "Accessibility label for button that displays Manage Insight options.")
        manageInsightButton.accessibilityHint = NSLocalizedString("Select to manage this Insight.", comment: "Accessibility hint for Manage Insight button.")
    }
}

private extension StatsCellHeader {

    // MARK: - Configure

    func applyStyles() {
        Style.configureHeaderCell(self)
        Style.configureLabelAsHeader(headerLabel)
        configureManageInsightButton()
        updateStackView()
    }

    func updateStackView() {
        // Only show the top padding if there is actually a label.
        stackViewTopConstraint.constant = headerLabel.text == "" ? 0 : defaultStackViewTopConstraint

        // Adjust the height if displaying on Post Stats with no title.
        stackViewHeightConstraint.constant = adjustHeightForPostStats ? emptyPostStatsHeight : defaultStackViewHeightConstraint
    }

    func configureManageInsightButton() {

        guard let statSection = statSection,
            StatSection.allInsights.contains(statSection) else {
                showManageInsightButton(false)
                return
        }

        showManageInsightButton()
        manageInsightImageView.image = Style.imageForGridiconType(.ellipsis, withTint: .darkGrey)
    }

    // MARK: - Button Action

    @IBAction func manageInsightButtonPressed(_ sender: UIButton) {
        guard let statSection = statSection else {
            DDLogDebug("manageInsightButtonPressed: unknown statSection.")
            return
        }

        siteStatsInsightsDelegate?.manageInsightSelected?(statSection, fromButton: sender)
    }

    func showManageInsightButton(_ show: Bool = true) {
        manageInsightImageView.isHidden = !show
        manageInsightButton.isHidden = !show
    }

}
