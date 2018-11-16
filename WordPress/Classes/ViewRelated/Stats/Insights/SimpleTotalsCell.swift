import UIKit

class SimpleTotalsCell: UITableViewCell {

    @IBOutlet weak var borderedView: UIView!
    @IBOutlet weak var headerStackView: UIStackView!
    @IBOutlet weak var subtitleStackView: UIStackView!
    @IBOutlet weak var rowsStackView: UIStackView!
    @IBOutlet weak var itemSubtitleLabel: UILabel!
    @IBOutlet weak var dataSubtitleLabel: UILabel!

    var showSubtitles = false {
        didSet {
            subtitleStackView.isHidden = !showSubtitles
        }
    }

    private typealias Style = WPStyleGuide.Stats

    override func awakeFromNib() {
        super.awakeFromNib()

        addHeader()
        applyStyles()

        subtitleStackView.isHidden = !showSubtitles
    }

}

private extension SimpleTotalsCell {

    func addHeader() {
        let header = StatsCellHeader.loadFromNib()
        headerStackView.insertArrangedSubview(header, at: 0)
    }

    func applyStyles() {
        Style.configureCell(self)
        Style.configureBorderForView(borderedView)

        Style.configureLabelAsSubtitle(itemSubtitleLabel)
        Style.configureLabelAsSubtitle(dataSubtitleLabel)
    }

}
