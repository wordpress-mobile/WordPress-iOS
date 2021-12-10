import UIKit

class ReaderDetailCommentsHeader: UITableViewHeaderFooterView, NibReusable {

    static let estimatedHeight: CGFloat = 80
    @IBOutlet weak var titleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.backgroundColor = .basicBackground
        titleLabel.textColor = .text
        titleLabel.font = WPStyleGuide.serifFontForTextStyle(.title3, fontWeight: .semibold)
    }

}
