import UIKit

final class AddressCell: UITableViewCell, ModelSettableCell {
    @IBOutlet weak var title: UILabel!

    var model: SiteAddress? {
        didSet {
            title.text = model?.title
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        styleTitle()
    }

    override func prepareForReuse() {
        title.text = ""
    }

    private func styleTitle() {

    }
}
