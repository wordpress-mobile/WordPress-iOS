import UIKit

class CustomizeInsightsCell: UITableViewCell, NibLoadable {

    // MARK: - Properties

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var laterLabel: UILabel!
    @IBOutlet weak var tryLabel: UILabel!
    @IBOutlet weak var bottomSeparatorLine: UIView!

    private typealias Style = WPStyleGuide.Stats

    // MARK: - Configure

    func configure() {
        applyStyles()
    }

}

// MARK: - Private Extension

private extension CustomizeInsightsCell {

    func applyStyles() {
        titleLabel.text = NSLocalizedString("Customize your insights", comment: "")
        contentLabel.text = NSLocalizedString("Create your own customized dashboard and choose what reports to see. Focus on the data you care most about.", comment: "")
        laterLabel.text = NSLocalizedString("Later", comment: "")
        tryLabel.text = NSLocalizedString("Try it now", comment: "")

        Style.configureCell(self)
        Style.configureLabelAsCustomizeTitle(titleLabel)
        Style.configureLabelAsSummary(contentLabel)
        Style.configureLabelAsCustomizeLater(laterLabel)
        Style.configureLabelAsCustomizeTry(tryLabel)
        Style.configureViewAsSeparator(bottomSeparatorLine)
    }

}
