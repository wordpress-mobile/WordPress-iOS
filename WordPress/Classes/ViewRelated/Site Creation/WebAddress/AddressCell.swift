import UIKit
import WordPressKit

final class AddressCell: UITableViewCell, ModelSettableCell {
    private struct TextStyleAttributes {
        static let defaults: [NSAttributedString.Key: Any] = [.font: WPStyleGuide.fontForTextStyle(.body, fontWeight: .regular),
                                                              .foregroundColor: UIColor.textSubtle]
        static let customName: [NSAttributedString.Key: Any] = [.font: WPStyleGuide.fontForTextStyle(.body, fontWeight: .regular),
                                                                .foregroundColor: UIColor.text]
    }

    @IBOutlet weak var title: UILabel!

    var model: DomainSuggestion? {
        didSet {
            title.attributedText = processName(model?.domainName)
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        selectedBackgroundView?.backgroundColor = .clear
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        styleCheckmark()
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        accessoryType = highlighted ? .checkmark : .none
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        accessoryType = selected ? .checkmark : .none
    }

    private func styleCheckmark() {
        tintColor = .primary(.shade40)
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
}

extension AddressCell {
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            preferredContentSizeDidChange()
        }
    }

    func preferredContentSizeDidChange() {
        title.attributedText = processName(model?.domainName)
    }
}
