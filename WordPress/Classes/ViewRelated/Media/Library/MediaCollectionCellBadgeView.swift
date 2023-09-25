import UIKit

final class MediaCollectionCellBadgeView: UIView {
    let textLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        textLabel.textColor = .white
        textLabel.font = WPStyleGuide.fontForTextStyle(.subheadline, fontWeight: .semibold)

        let stack = UIStackView(arrangedSubviews: [textLabel])
        stack.axis = .vertical
        stack.alignment = .center

        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        self.pinSubviewToAllEdges(stack, insets: .init(top: 3, left: 6, bottom: 3, right: 6))

        backgroundColor = .primary

        layer.borderColor = UIColor.white.cgColor
        layer.borderWidth = 1.5

        widthAnchor.constraint(greaterThanOrEqualToConstant: 24).isActive = true
        heightAnchor.constraint(greaterThanOrEqualToConstant: 24).isActive = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        layer.cornerRadius = bounds.height / 2
    }
}
