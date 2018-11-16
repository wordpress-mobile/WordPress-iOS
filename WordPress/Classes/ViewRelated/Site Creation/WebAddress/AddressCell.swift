import UIKit
import WordPressKit

final class AddressCell: UITableViewCell, ModelSettableCell {
    @IBOutlet weak var title: UILabel!

    var model: DomainSuggestion? {
        didSet {
            title.text = model?.domainName
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
