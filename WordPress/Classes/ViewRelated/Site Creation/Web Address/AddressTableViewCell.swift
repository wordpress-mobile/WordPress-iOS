import UIKit
import WordPressKit

final class AddressTableViewCell: UITableViewCell {

    // MARK: - Dependencies

    private var domainPurchasingEnabled: Bool {
        RemoteFeatureFlag.plansInSiteCreation.enabled()
    }

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
        let length = Appearance.dotViewRadius * 2
        let view = UIView()
        view.clipsToBounds = true
        view.layer.cornerRadius = Appearance.dotViewRadius
        view.translatesAutoresizingMaskIntoConstraints = true
        view.frame.size = .init(width: length, height: length)
        return view
    }()

    private let checkmarkImageView: UIView = {
        let configuration = UIImage.SymbolConfiguration(weight: .semibold)
        let image = UIImage(systemName: "checkmark", withConfiguration: configuration)
        let view = UIImageView()
        view.isHidden = true
        view.image = image
        view.translatesAutoresizingMaskIntoConstraints = true
        view.sizeToFit()
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
        self.accessibilityTraits = .button
        self.accessibilityHint = NSLocalizedString(
            "Selects this domain to use for your site.",
            comment: "Accessibility hint for a domain in the Site Creation domains list."
        )
        if domainPurchasingEnabled {
            self.accessibilityElements = [domainLabel, tagsLabel, costLabel]
        } else {
            self.selectedBackgroundView?.backgroundColor = .clear
        }
    }

    private func setupSubviews() {
        let domainAndTag = Self.stackedViews([domainLabel, tagsLabel], axis: .vertical, alignment: .fill, distribution: .fill, spacing: 2)
        let main = Self.stackedViews([domainAndTag, costLabel], axis: .horizontal, alignment: .center, distribution: .equalCentering, spacing: 0)
        main.translatesAutoresizingMaskIntoConstraints = false
        main.isLayoutMarginsRelativeArrangement = true
        main.directionalLayoutMargins = Appearance.contentMargins
        self.contentView.addSubview(main)
        self.contentView.pinSubviewToAllEdges(main)
        self.updatePriceLabelTextAlignment()
        self.contentView.addSubview(dotView)
        self.contentView.addSubview(checkmarkImageView)
        self.selectedBackgroundView = {
            let view = UIView()
            view.backgroundColor = UIColor(light: .secondarySystemBackground, dark: .tertiarySystemBackground)
            return view
        }()
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        [dotView, checkmarkImageView].forEach { view in
            view.center = CGPoint(x: Appearance.contentMargins.leading / 2, y: bounds.midY)
        }
    }

    // MARK: - React to Trait Collection Changes

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.layoutDirection != previousTraitCollection?.layoutDirection {
            self.updatePriceLabelTextAlignment()
        }
    }

    // MARK: - Updating UI

    /// This is the new update method and it's called when `domainPurchasing` feature flag is enabled.
    func update(with viewModel: ViewModel) {
        self.domainLabel.text = viewModel.domain
        self.tagsLabel.attributedText = Self.tagsAttributedString(tags: viewModel.tags)
        self.tagsLabel.isHidden = viewModel.tags.isEmpty
        self.costLabel.attributedText = Self.costAttributedString(cost: viewModel.cost)
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
        for (index, tag) in tags.enumerated() {
            let attributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: Appearance.tagTextColor(tag)
            ]
            let string = index == 0 ? tag.localizedString : "\n\(tag.localizedString)"
            attributedString.append(.init(string: string, attributes: attributes))
        }
        return attributedString
    }

    private static func costAttributedString(cost: ViewModel.Cost) -> NSAttributedString {
        switch cost {
        case .free:
            let attributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor.label,
                .font: Appearance.regularCostFont
            ]
            return NSAttributedString(string: ViewModel.Strings.free, attributes: attributes)
        case .regular(let cost):
            var attributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor.label,
                .font: Appearance.regularCostFont
            ]
            let attributedString = NSMutableAttributedString(string: cost, attributes: attributes)
            attributes[.font] = Appearance.smallCostFont
            attributedString.append(.init(string: "\n\(ViewModel.Strings.yearly)", attributes: attributes))
            return attributedString
        case .onSale(let cost, let sale):
            let saleAttributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: Appearance.saleCostTextColor,
                .font: Appearance.semiboldCostFont
            ]
            let costAttributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor.secondaryLabel,
                .font: Appearance.smallCostFont,
                .strikethroughStyle: NSUnderlineStyle.single.rawValue
            ]
            let firstYearAttributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: Appearance.saleCostTextColor,
                .font: Appearance.smallCostFont
            ]
            let attributedString = NSMutableAttributedString(string: cost, attributes: costAttributes)
            attributedString.append(NSAttributedString(string: " \(sale)", attributes: saleAttributes))
            attributedString.append(.init(string: "\n\(ViewModel.Strings.firstYear)", attributes: firstYearAttributes))
            return attributedString
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

    enum Appearance {

        static let contentMargins = NSDirectionalEdgeInsets(top: 16, leading: 40, bottom: 16, trailing: 16)

        static let domainFont = WPStyleGuide.fontForTextStyle(.body, fontWeight: .regular)
        static let domainTextColor = UIColor.text

        static let regularCostFont = WPStyleGuide.fontForTextStyle(.body, fontWeight: .regular)
        static let semiboldCostFont = WPStyleGuide.fontForTextStyle(.body, fontWeight: .semibold)
        static let smallCostFont = WPStyleGuide.fontForTextStyle(.footnote, fontWeight: .regular)
        static let saleCostTextColor = UIColor(light: .muriel(name: .jetpackGreen, .shade50), dark: .muriel(name: .jetpackGreen, .shade30))

        static let tagFont = WPStyleGuide.fontForTextStyle(.footnote, fontWeight: .regular)
        static let tagTextColor: (ViewModel.Tag?) -> UIColor = { tag in
            guard let tag else {
                return .clear
            }
            switch tag {
            case .recommended: return UIColor(light: .muriel(name: .jetpackGreen, .shade50), dark: .muriel(name: .jetpackGreen, .shade30))
            case .bestAlternative: return UIColor(light: .muriel(name: .purple, .shade50), dark: .muriel(name: .purple, .shade30))
            case .sale: return UIColor(light: .muriel(name: .yellow, .shade50), dark: .muriel(name: .yellow, .shade30))
            }
        }

        static let dotViewRadius: CGFloat = 4
        static let dotColor: (ViewModel.Tag?) -> UIColor = Appearance.tagTextColor
    }
}

// MARK: - Old Table View Cell Design

extension AddressTableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        styleCheckmark()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        if domainPurchasingEnabled {
            super.setSelected(selected, animated: animated)
            self.checkmarkImageView.isHidden = !selected
            self.dotView.isHidden = !checkmarkImageView.isHidden
        } else {
            accessoryType = selected ? .checkmark : .none
        }
    }

    private func styleCheckmark() {
        tintColor = .primary(.shade40)
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        update(with: nil as DomainSuggestion?)
        borders.forEach({ $0.removeFromSuperview() })
        borders = []
    }

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
