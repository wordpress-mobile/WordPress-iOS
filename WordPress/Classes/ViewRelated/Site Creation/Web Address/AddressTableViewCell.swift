import UIKit
import WordPressKit

final class AddressTableViewCell: UITableViewCell {

    // MARK: - Dependencies

    private let domainPurchasingEnabled = FeatureFlag.siteCreationDomainPurchasing.enabled

    // MARK: - Views

    private var borders = [UIView]()

    private let domainLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.font = Appearance.domainFont
        label.textColor = Appearance.domainTextColor
        return label
    }()

    private let tagsLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.font = Appearance.tagFont
        return label
    }()

    private let dotView: UIView = {
        let size = Appearance.dotViewRadius * 2
        let view = UIView()
        view.clipsToBounds = true
        view.layer.cornerRadius = Appearance.dotViewRadius
        NSLayoutConstraint.activate([
            view.widthAnchor.constraint(equalToConstant: size),
            view.heightAnchor.constraint(equalTo: view.widthAnchor)
        ])
        return view
    }()

    private let costLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.font = Appearance.domainFont
        label.textColor = Appearance.domainTextColor
        label.numberOfLines = 2
        return label
    }()

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
        if domainPurchasingEnabled {
            setupSubviews()
        }
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

    private func setupSubviews() {
        let domainAndTag = Self.stackedViews([domainLabel, tagsLabel], axis: .vertical, alignment: .fill, distribution: .fill, spacing: 2)
        let dotAndLabels = Self.stackedViews([dotView, domainAndTag], axis: .horizontal, alignment: .center, distribution: .fill, spacing: 8)
        let main = Self.stackedViews([dotAndLabels, costLabel], axis: .horizontal, alignment: .center, distribution: .equalCentering, spacing: 0)
        main.translatesAutoresizingMaskIntoConstraints = false
        main.isLayoutMarginsRelativeArrangement = true
        main.directionalLayoutMargins = Appearance.contentMargins
        self.contentView.addSubview(main)
        self.contentView.pinSubviewToAllEdges(main)
        self.updatePriceLabelTextAlignment()
    }

    // MARK: - React to Trait Collection Changes

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.layoutDirection != previousTraitCollection?.layoutDirection {
            self.updatePriceLabelTextAlignment()
        }
    }

    // MARK: - Lifecycle

    override func awakeFromNib() {
        super.awakeFromNib()
        styleCheckmark()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        if domainPurchasingEnabled {
            super.setSelected(selected, animated: animated)
        } else {
            accessoryType = selected ? .checkmark : .none
        }
    }

    private func styleCheckmark() {
        tintColor = .primary(.shade40)
    }

    override func prepareForReuse() {
        update(with: nil as DomainSuggestion?)
        borders.forEach({ $0.removeFromSuperview() })
        borders = []
    }

    // MARK: - Updating UI

    /// This is the new update method and it's called when `domainPurchasing` feature flag is enabled.
    func update(with viewModel: ViewModel) {
        self.domainLabel.text = viewModel.domain
        self.tagsLabel.attributedText = Self.tagsAttributedString(tags: viewModel.tags)
        self.tagsLabel.isHidden = viewModel.tags.isEmpty
        self.costLabel.attributedText = Self.priceAttributedString(price: viewModel.cost, discount: viewModel.saleCost)
        self.dotView.backgroundColor = Appearance.dotColor(viewModel.tags.first)
    }

    /// Updates the `costLabel` text alignment.
    private func updatePriceLabelTextAlignment() {
        switch traitCollection.layoutDirection {
        case .rightToLeft:
            // swiftlint:disable:next natural_text_alignment
            self.costLabel.textAlignment = .left
        default:
            // swiftlint:disable:next inverse_text_alignment
            self.costLabel.textAlignment = .right
        }
    }

    // MARK: - Helpers

    private static func tagsAttributedString(tags: [ViewModel.Tag]) -> NSAttributedString? {
        guard !tags.isEmpty else {
            return nil
        }
        let attributedString = NSMutableAttributedString()
        let separatorAttributes: [NSAttributedString.Key: Any] = [
            .font: Appearance.tagFont,
            .foregroundColor: UIColor.tertiaryLabel
        ]
        for (index, tag) in tags.enumerated() {
            let attributes: [NSAttributedString.Key: Any] = [
                .font: Appearance.tagFont,
                .foregroundColor: Appearance.tagTextColor(tag)
            ]
            attributedString.append(.init(string: tag.localizedString, attributes: attributes))
            if index + 1 < tags.count {
                attributedString.append(.init(string: " • ", attributes: separatorAttributes))
            }
        }
        return attributedString
    }

    private static func priceAttributedString(price: String, discount: String?) -> NSAttributedString {
        if let discount {
            let discountAttributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor.systemGreen,
                .font: Appearance.regularPriceFont
            ]
            let priceAttributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor.systemGray,
                .font: Appearance.smallPriceFont,
                .strikethroughStyle: NSUnderlineStyle.single.rawValue
            ]
            let attributedString = NSMutableAttributedString(string: discount, attributes: discountAttributes)
            attributedString.append(NSAttributedString(string: "\n\(price)", attributes: priceAttributes))
            return attributedString
        } else {
            let attributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor.systemGray,
                .font: Appearance.regularPriceFont
            ]
            return NSAttributedString(string: price, attributes: attributes)
        }
    }

    private static func stackedViews(
        _ subviews: [UIView],
        axis: NSLayoutConstraint.Axis,
        alignment: UIStackView.Alignment,
        distribution: UIStackView.Distribution,
        spacing: CGFloat) -> UIStackView {
        let stackView = UIStackView(arrangedSubviews: subviews)
        stackView.axis = axis
        stackView.alignment = alignment
        stackView.distribution = distribution
        stackView.spacing = spacing
        return stackView
    }

    // MARK: - Constants

    private enum Appearance {

        static let contentMargins = NSDirectionalEdgeInsets(top: 16, leading: 8, bottom: 16, trailing: 16)

        static let domainFont = WPStyleGuide.fontForTextStyle(.body, fontWeight: .regular)
        static let domainTextColor = UIColor.text

        static let semiboldPriceFont = WPStyleGuide.fontForTextStyle(.callout, fontWeight: .semibold)
        static let regularPriceFont = WPStyleGuide.fontForTextStyle(.callout, fontWeight: .regular)
        static let smallPriceFont = WPStyleGuide.fontForTextStyle(.footnote, fontWeight: .regular)

        static let tagFont = WPStyleGuide.fontForTextStyle(.footnote, fontWeight: .regular)
        static let tagTextColor: (ViewModel.Tag?) -> UIColor = { tag in
            guard let tag else {
                return .clear
            }
            switch tag {
            case .recommended: return .systemGreen
            case .bestAlternative: return .systemPurple
            case .sale: return .systemOrange
            }
        }

        static let dotViewRadius: CGFloat = 4
        static let dotColor: (ViewModel.Tag?) -> UIColor = Appearance.tagTextColor
    }
}

// MARK: - Old Table View Cell Design

extension AddressTableViewCell {

    func update(with model: DomainSuggestion?) {
        self.textLabel?.attributedText = AddressTableViewCell.processName(model?.domainName)
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

    static var estimatedSize: CGSize {
        return CGSize(width: 320, height: 45)
    }

    private struct TextStyleAttributes {
        static let defaults: [NSAttributedString.Key: Any] = [.font: WPStyleGuide.fontForTextStyle(.body, fontWeight: .regular),
                                                              .foregroundColor: UIColor.textSubtle]
        static let customName: [NSAttributedString.Key: Any] = [.font: WPStyleGuide.fontForTextStyle(.body, fontWeight: .regular),
                                                                .foregroundColor: UIColor.text]
    }
}
