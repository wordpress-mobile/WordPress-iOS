import UIKit

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
        titleLabel?.font = WPStyleGuide.serifFontForTextStyle(.body, fontWeight: .semibold)
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
