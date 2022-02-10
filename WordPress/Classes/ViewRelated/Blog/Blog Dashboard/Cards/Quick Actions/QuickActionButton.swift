import UIKit

final class QuickActionButton: UIButton {

    var onTap: (() -> Void)?

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
