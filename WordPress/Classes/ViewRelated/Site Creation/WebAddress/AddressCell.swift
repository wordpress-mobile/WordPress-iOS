import UIKit
import WordPressKit

final class AddressCell: UITableViewCell, ModelSettableCell {
    /// A manually computed width of the accessory view (checkmark) when it is shown.
    private static let checkmarkAccessoryViewWidth: CGFloat = 39

    private struct TextStyleAttributes {
        static let defaults: [NSAttributedString.Key: Any] = [.font: WPStyleGuide.fontForTextStyle(.body, fontWeight: .regular), .foregroundColor: WPStyleGuide.grey()]
        static let customName: [NSAttributedString.Key: Any] = [.font: WPStyleGuide.fontForTextStyle(.body, fontWeight: .regular), .foregroundColor: WPStyleGuide.darkGrey()]
    }

    /// Used for recomputing the trailing constraint constant of `title`.
    private var originalTitleTrailingConstraintConstant: CGFloat!

    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var titleTrailingConstraint: NSLayoutConstraint! {
        didSet {
            originalTitleTrailingConstraintConstant = titleTrailingConstraint.constant
        }
    }

    var model: DomainSuggestion? {
        didSet {
            title.attributedText = processName(model?.domainName)
        }
    }

    override var accessoryType: UITableViewCell.AccessoryType {
        didSet {
            // Recompute the constraint of the title to always have an empty space for the
            // checkmark even if it is not shown.
            let isChecked = accessoryType == .checkmark

            titleTrailingConstraint.constant = originalTitleTrailingConstraintConstant
                + (isChecked ? 0 : AddressCell.checkmarkAccessoryViewWidth)
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
        tintColor = WPStyleGuide.mediumBlue()
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
