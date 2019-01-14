import UIKit
import WordPressKit

final class AddressCell: UITableViewCell, ModelSettableCell {
    @IBOutlet weak var title: UILabel!

    private struct TextStyleAttributes {
        static let defaults: [NSAttributedString.Key: Any] = [.font: WPStyleGuide.fontForTextStyle(.body, fontWeight: .regular), .foregroundColor: WPStyleGuide.grey()]
        static let customName: [NSAttributedString.Key: Any] = [.font: WPStyleGuide.fontForTextStyle(.body, fontWeight: .regular), .foregroundColor: WPStyleGuide.darkGrey()]
    }

    var model: DomainSuggestion? {
        didSet {
            title.attributedText = processName(model?.domainName)
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        styleTitle()
    }

    override func prepareForReuse() {
        title.attributedText = nil
    }

    private func processName(_ domainName: String?) -> NSAttributedString? {
        guard let name = domainName else {
            return nil
        }

        guard let customName = name.components(separatedBy: ".").first else {
            return nil
        }

        let completeDomainName = NSMutableAttributedString(string: name, attributes: TextStyleAttributes.defaults)

        let rangeOfCustomName = NSRange(location: 0, length: customName.count)

        completeDomainName.setAttributes(TextStyleAttributes.customName, range: rangeOfCustomName)

        return completeDomainName
    }

    private func styleTitle() {

    }
}
