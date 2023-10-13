import UIKit

final class SiteMediaCollectionCellBadgeView: UIView {
    let textLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        textLabel.textColor = .white
        textLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 15, weight: .semibold)

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

    func setBadge(_ badge: SiteMediaCollectionCellViewModel.BadgeType) {
        switch badge {
        case .unordered:
            textLabel.attributedText = NSAttributedString(attachment: {
                let attachment = NSTextAttachment()
                let configuration = UIImage.SymbolConfiguration(font: UIFont.systemFont(ofSize: 11, weight: .semibold))
                attachment.image = UIImage(systemName: "checkmark", withConfiguration: configuration)?.withTintColor(.white, renderingMode: .alwaysTemplate)
                return attachment
            }(), attributes: [
                NSAttributedString.Key.baselineOffset: 1 // It doesn't appear visually centered othwerwise
            ])
        case .ordered(let index):
            textLabel.text = (index + 1).description
        }
    }
}
