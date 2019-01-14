import UIKit
import WordPressKit

final class AddressCell: UITableViewCell, ModelSettableCell {
    @IBOutlet weak var title: UILabel!

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

        let components = name.components(separatedBy: ".")

        guard let customName = components.first else {
            return nil
        }

        let regularAttributes: [NSAttributedString.Key: Any] = [.font: WPStyleGuide.fontForTextStyle(.body, fontWeight: .regular),
                                                                   .foregroundColor: WPStyleGuide.grey()]
        let fullString = NSMutableAttributedString(string: name, attributes: regularAttributes)

        let rangeOfDomain = NSRange(location: 0, length: customName.count)


        let customNameAttributes: [NSAttributedString.Key: Any] = [.font: WPStyleGuide.fontForTextStyle(.body, fontWeight: .regular),
                                                                   .foregroundColor: WPStyleGuide.darkGrey()]

        fullString.setAttributes(customNameAttributes, range: rangeOfDomain)

        return fullString
    }

    private func styleTitle() {

    }
}
