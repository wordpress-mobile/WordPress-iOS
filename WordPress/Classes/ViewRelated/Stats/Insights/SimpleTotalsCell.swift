import UIKit

class SimpleTotalsCell: UITableViewCell {

    @IBOutlet weak var borderedView: UIView!
    @IBOutlet weak var headerStackView: UIStackView!
    @IBOutlet weak var subtitleStackView: UIStackView!
    @IBOutlet weak var rowsStackView: UIStackView!
    @IBOutlet weak var itemSubtitleLabel: UILabel!
    @IBOutlet weak var dataSubtitleLabel: UILabel!

    private let headerView = StatsCellHeader.loadFromNib()

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

        // TODO: remove these.
//        addExampleRows()
        addSimpleTotalsRows()

        subtitleStackView.isHidden = !showSubtitles
    }

}

private extension SimpleTotalsCell {

    func addHeader() {
        headerView.headerLabel.text = "Fancy Stat Card"
        headerStackView.insertArrangedSubview(headerView, at: 0)
    }

    func applyStyles() {
        Style.configureCell(self)
        Style.configureBorderForView(borderedView)
        Style.configureLabelAsSubtitle(itemSubtitleLabel)
        Style.configureLabelAsSubtitle(dataSubtitleLabel)
    }

    func addSimpleTotalsRows() {
        let labelText = "Simple total row"

        // It's the first row. Let's remove that separator line.
        let row1 = StatsTotalRow.loadFromNib()
        row1.imageView.image = Style.imageForGridiconType(.posts)
        row1.showSeparator = false
        row1.itemLabel.text = labelText
        rowsStackView.addArrangedSubview(row1)

        // Let's add some rows.
        for _ in (1...2) {
            let row = StatsTotalRow.loadFromNib()
            row.itemLabel.text = labelText
            row.imageView.image = Style.imageForGridiconType(.posts)
            rowsStackView.addArrangedSubview(row)
        }

        // Let's show what the 'Best Views Ever' will look like with the detail label.
        let bveRow = StatsTotalRow.loadFromNib()
        bveRow.imageView.image = Style.imageForGridiconType(.posts)
        bveRow.itemLabel.text = "Best Views Ever"
        bveRow.showItemDetailLabel = true
        bveRow.itemDetailLabel.text = "Nov 15, 2018"
        rowsStackView.addArrangedSubview(bveRow)
    }

    func addExampleRows() {

        // This method examples the different row states.
        // To be replaced with real data.

        showSubtitles = true
        headerView.showManageInsightButton = true

        // It's the first row. Let's remove that separator line.
        let row1 = StatsTotalRow.loadFromNib()
        row1.showSeparator = false
        row1.showImage = false
        row1.itemLabel.text = "I am but a simple row"
        rowsStackView.addArrangedSubview(row1)

        // Let's show the item detail label.
        let row2 = StatsTotalRow.loadFromNib()
        row2.showItemDetailLabel = true
        row2.showImage = false
        row2.itemLabel.text = "What's that below me?"
        row2.itemDetailLabel.text = "Do you see me?"
        rowsStackView.addArrangedSubview(row2)

        // Let's show an image.
        let row3 = StatsTotalRow.loadFromNib()
        row3.imageView.image = Style.imageForGridiconType(.posts)
        row3.itemLabel.text = "What's that to my left?"
        rowsStackView.addArrangedSubview(row3)

        // Let's show a disclosure.
        let row4 = StatsTotalRow.loadFromNib()
        row4.imageView.image = Style.imageForGridiconType(.posts)
        row4.showDisclosure = true
        row4.itemLabel.text = "What's that arrow thing over there?"
        rowsStackView.addArrangedSubview(row4)
    }

}
