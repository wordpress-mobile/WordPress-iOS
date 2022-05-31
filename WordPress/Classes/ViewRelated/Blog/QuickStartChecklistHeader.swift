import UIKit

class QuickStartChecklistHeader: UITableViewHeaderFooterView, NibReusable {

    // MARK: Public Variables

    var title: String? {
        didSet {
            titleLabel.text = title
        }
    }

    // MARK: Outlets

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!

    // MARK: View Lifecycle

    override func awakeFromNib() {
        super.awakeFromNib()
        imageView.image = AppStyleGuide.quickStartExistingSite
        titleLabel.font = WPStyleGuide.serifFontForTextStyle(.title1, fontWeight: .semibold)
    }
}
