import UIKit
import WordPressKit

final class AddressTableViewCell: UITableViewCell, ModelSettableCell {

    // MARK: - Constants

    static var estimatedSize: CGSize {
        return CGSize(width: 320, height: 45)
    }

    private struct TextStyleAttributes {
        static let defaults: [NSAttributedString.Key: Any] = [.font: WPStyleGuide.fontForTextStyle(.body, fontWeight: .regular),
                                                              .foregroundColor: UIColor.textSubtle]
        static let customName: [NSAttributedString.Key: Any] = [.font: WPStyleGuide.fontForTextStyle(.body, fontWeight: .regular),
                                                                .foregroundColor: UIColor.text]
    }

    // MARK: - Views

    var borders = [UIView]()

    @IBOutlet weak var title: UILabel!

    var model: DomainSuggestion? {
        didSet {
            title.attributedText = AddressTableViewCell.processName(model)
        }
    }

    // MARK: - Init

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

    // MARK: - Lifecycle

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

    // MARK: - Reacting to Traits Changes

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            preferredContentSizeDidChange()
        }
    }

    private func preferredContentSizeDidChange() {
        title.attributedText = AddressTableViewCell.processName(model)
    }

    // MARK: - Updating UI

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

    // MARK: - Helpers

    public static func processName(_ suggestion: DomainSuggestion?) -> NSAttributedString? {
        guard let cost = suggestion?.costString,
              let attributedString = AddressTableViewCell.processName(suggestion?.domainName) else {
            return nil
        }
        guard FeatureFlag.siteCreationDomainPurchasing.enabled else {
            return attributedString
        }
        let mutable = NSMutableAttributedString(attributedString: attributedString)
        mutable.append(.init(string: " (\(cost))", attributes: TextStyleAttributes.defaults))
        return mutable
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
