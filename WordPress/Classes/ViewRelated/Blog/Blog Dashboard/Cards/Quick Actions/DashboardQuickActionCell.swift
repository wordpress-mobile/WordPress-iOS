import UIKit

#warning("TODO: reimplement spotlight thing")
final class DashboardQuickActionCell: UITableViewCell {
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let detailsLabel = UILabel()

    var isSeparatorHidden = false {
        didSet {
            guard oldValue != isSeparatorHidden else { return }
            refreshSeparator()
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        createView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func createView() {
        titleLabel.font = WPStyleGuide.fontForTextStyle(.headline, fontWeight: .medium)
        titleLabel.adjustsFontForContentSizeCategory = true

        iconView.tintColor = .label

        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        spacer.widthAnchor.constraint(greaterThanOrEqualToConstant: 8).isActive = true

        detailsLabel.font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .regular)
        detailsLabel.textColor = .secondaryLabel
        detailsLabel.adjustsFontForContentSizeCategory = true

        let stackView = UIStackView(arrangedSubviews: [iconView, titleLabel, spacer, detailsLabel])
        stackView.alignment = .center
        stackView.spacing = 16
        stackView.isUserInteractionEnabled = false

        contentView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.pinSubviewToAllEdges(stackView, insets: UIEdgeInsets(top: 13, left: 16, bottom: 13, right: 16))
    }

    func configure(_ viewModel: DashboardQuickActionItemViewModel) {
        titleLabel.text = viewModel.title
        iconView.image = viewModel.image?.withRenderingMode(.alwaysTemplate)
        detailsLabel.text = viewModel.details
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        refreshSeparator()
    }

    private func refreshSeparator() {
        if isSeparatorHidden {
            separatorInset = UIEdgeInsets(top: 0, left: bounds.width, bottom: 0, right: 0)
        } else {
            let titleLabelFrame = contentView.convert(titleLabel.frame, from: titleLabel.superview)
            separatorInset = UIEdgeInsets(top: 0, left: titleLabelFrame.origin.x, bottom: 0, right: 0)
        }
    }
}

#warning("TODO: remove")
final class QuickActionButton: UIButton {

    var onTap: (() -> Void)?

    var shouldShowSpotlight: Bool = false {
        didSet {
            spotlightView.isHidden = !shouldShowSpotlight
        }
    }

    private lazy var spotlightView: QuickStartSpotlightView = {
        let spotlightView = QuickStartSpotlightView()
        spotlightView.translatesAutoresizingMaskIntoConstraints = false
        spotlightView.isHidden = true
        return spotlightView
    }()

    convenience init(title: String, image: UIImage) {
        self.init(frame: .zero)
        setTitle(title, for: .normal)
        setImage(image, for: .normal)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }

    private func setup() {
        configureTitleLabel()
        configureInsets()
        configureSpotlightView()

        layer.cornerRadius = Metrics.cornerRadius
        backgroundColor = .listForeground
        tintColor = .listIcon

        addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
    }

    private func configureTitleLabel() {
        titleLabel?.adjustsFontForContentSizeCategory = true
        titleLabel?.font = AppStyleGuide.prominentFont(textStyle: .body, weight: .semibold)
        setTitleColor(.text, for: .normal)
    }

    private func configureInsets() {
        contentEdgeInsets = Metrics.contentEdgeInsets
        titleEdgeInsets = Metrics.titleEdgeInsets
    }

    private func configureSpotlightView() {
        addSubview(spotlightView)
        bringSubviewToFront(spotlightView)

        NSLayoutConstraint.activate(
            [
                spotlightView.centerYAnchor.constraint(equalTo: centerYAnchor),
                spotlightView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Metrics.spotlightOffset)
            ]
        )
    }

    @objc private func buttonTapped() {
        onTap?()
    }
}

extension QuickActionButton {

    private enum Metrics {
        static let cornerRadius = 8.0
        static let titleHorizontalOffset = 12.0
        static let contentVerticalOffset = 12.0
        static let contentLeadingOffset = 16.0
        static let contentTrailingOffset = 24.0
        static let spotlightOffset = 8.0

        static let contentEdgeInsets = UIEdgeInsets(
            top: contentVerticalOffset,
            left: contentLeadingOffset,
            bottom: contentVerticalOffset,
            right: contentTrailingOffset + titleHorizontalOffset
        ).flippedForRightToLeft

        static let titleEdgeInsets = UIEdgeInsets(
            top: 0,
            left: titleHorizontalOffset,
            bottom: 0,
            right: -titleHorizontalOffset
        ).flippedForRightToLeft
    }
}
