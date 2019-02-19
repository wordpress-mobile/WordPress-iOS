import UIKit

protocol ViewMoreRowDelegate: class {
    func viewMoreSelectedForStatSection(_ statSection: StatSection)
}

class ViewMoreRow: UIView, NibLoadable {

    // MARK: - Properties

    @IBOutlet weak var viewMoreLabel: UILabel!

    private var statSection: StatSection?
    private weak var delegate: ViewMoreRowDelegate?

    // MARK: - Configure

    func configure(statSection: StatSection?, delegate: ViewMoreRowDelegate?) {
        self.statSection = statSection
        self.delegate = delegate
        applyStyles()
    }

}

// MARK: - Private Methods

private extension ViewMoreRow {

    func applyStyles() {
        viewMoreLabel.text = NSLocalizedString("View more", comment: "Label for viewing more stats.")
        viewMoreLabel.textColor = WPStyleGuide.Stats.actionTextColor
    }

    @IBAction func didTapViewMoreButton(_ sender: UIButton) {
        guard let statSection = statSection else {
            return
        }

        delegate?.viewMoreSelectedForStatSection(statSection)
    }

}
