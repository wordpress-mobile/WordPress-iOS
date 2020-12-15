import UIKit
import WordPressKit

final class AddressCell: UITableViewCell, ModelSettableCell {
    static var estimatedSize: CGSize {
        return CGSize(width: 320, height: 45)
    }
    private struct TextStyleAttributes {
        static let defaults: [NSAttributedString.Key: Any] = [.font: WPStyleGuide.fontForTextStyle(.body, fontWeight: .regular),
                                                              .foregroundColor: UIColor.textSubtle]
        static let customName: [NSAttributedString.Key: Any] = [.font: WPStyleGuide.fontForTextStyle(.body, fontWeight: .regular),
                                                                .foregroundColor: UIColor.text]
    }
    var borders = [UIView]()
    @IBOutlet weak var title: UILabel!

    var model: DomainSuggestion? {
        didSet {
            title.attributedText = AddressCell.processName(model?.domainName)
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

        accessibilityTraits = .button
        accessibilityHint = NSLocalizedString("Selects this domain to use for your site.",
                                              comment: "Accessibility hint for a domain in the Site Creation domains list.")
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        styleCheckmark()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        accessoryType = selected ? .checkmark : .none
    }

    private func styleCheckmark() {
        tintColor = .primary(.shade40)
    }

    override func prepareForReuse() {
        title.attributedText = nil
        borders.forEach({ $0.removeFromSuperview() })
        borders = []
    }

    public func addBorder(isFirstCell: Bool = false, isLastCell: Bool = false) {
        if isFirstCell {
            let border = addTopBorder(withColor: .divider)
            borders.append(border)
        }

        if isLastCell {
            let border = addBottomBorder(withColor: .divider)
            borders.append(border)
        } else {
            let border = addBottomBorder(withColor: .divider, leadingMargin: 20)
            borders.append(border)
        }
    }

    public static func processName(_ domainName: String?) -> NSAttributedString? {
        guard let name = domainName,
              let customName = name.components(separatedBy: ".").first else {
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
        title.attributedText = AddressCell.processName(model?.domainName)
    }
}
