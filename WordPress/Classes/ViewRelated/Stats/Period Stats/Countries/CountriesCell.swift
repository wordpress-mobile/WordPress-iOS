import UIKit

class CountriesCell: UITableViewCell, NibLoadable {

    // MARK: - Properties

    @IBOutlet weak var separatorLine: UIView!
    @IBOutlet weak var subtitleStackView: UIStackView!
    @IBOutlet weak var rowsStackView: UIStackView!
    @IBOutlet weak var itemSubtitleLabel: UILabel!
    @IBOutlet weak var dataSubtitleLabel: UILabel!

    // If the subtitles are not shown, this is active.
    @IBOutlet weak var rowsStackViewTopConstraint: NSLayoutConstraint!
    // If the subtitles are shown, this is active.
    @IBOutlet weak var rowsStackViewTopConstraintWithSubtitles: NSLayoutConstraint!

    private var dataRows = [StatsTotalRowData]()
    private typealias Style = WPStyleGuide.Stats

    // MARK: - Configure

    func configure(itemSubtitle: String,
                   dataSubtitle: String,
                   dataRows: [StatsTotalRowData]) {
        itemSubtitleLabel.text = itemSubtitle
        dataSubtitleLabel.text = dataSubtitle
        self.dataRows = dataRows

        addRows(dataRows, toStackView: rowsStackView, forType: .period)
        setSubtitleVisibility()
        applyStyles()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        removeRowsFromStackView(rowsStackView)
    }

}

private extension CountriesCell {

    func applyStyles() {
        Style.configureCell(self)
        Style.configureLabelAsSubtitle(itemSubtitleLabel)
        Style.configureLabelAsSubtitle(dataSubtitleLabel)
        Style.configureViewAsSeperator(separatorLine)
    }

    func setSubtitleVisibility() {
        let showSubtitles = dataRows.count > 0
        subtitleStackView.isHidden = !showSubtitles
        rowsStackViewTopConstraint.isActive = !showSubtitles
        rowsStackViewTopConstraintWithSubtitles.isActive = showSubtitles
    }

}
