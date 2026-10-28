import UIKit
import WordPressShared
import Gridicons
import CoreGraphics
import WordPressUI

class ExpandableCell: WPReusableTableViewCell {

    // MARK: - Initializers

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public required override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        buildSubviews()
        setupSubviews()
    }

    let titleTextLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isOpaque = false
        label.backgroundColor = nil
        label.isUserInteractionEnabled = false
        label.contentMode = .left
        label.textAlignment = .natural
        label.numberOfLines = 0
        label.font = .preferredFont(forTextStyle: .callout)
        label.adjustsFontForContentSizeCategory = true
        label.setContentHuggingPriority(UILayoutPriority(251), for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        return label
    }()

    let expandableTextView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isHidden = true
        textView.isScrollEnabled = false
        textView.clipsToBounds = true
        textView.isEditable = false
        textView.font = .systemFont(ofSize: 14)
        textView.autocapitalizationType = .sentences
        return textView
    }()

    let chevronImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleToFill
        imageView.setContentHuggingPriority(.required, for: .horizontal)
        imageView.setContentHuggingPriority(.required, for: .vertical)
        return imageView
    }()

    public var urlCallback: ((URL) -> Void)?

    public var expanded: Bool = false {
        didSet {
            self.expandableTextView.isHidden = !self.expanded

            let transform: CGAffineTransform
            let alpha: CGFloat

            if self.expanded {
                transform = CGAffineTransform(rotationAngle: CGFloat.pi)
                alpha = 1
            } else {
                transform = CGAffineTransform.identity
                alpha = 0
            }

            UIView.animate(withDuration: 0.2) {
                self.chevronImageView.transform = transform
                self.expandableTextView.alpha = alpha
            }
        }
    }

    public func toggle() {
        expanded.toggle()
    }

    private func buildSubviews() {
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
        clipsToBounds = true

        let headerStackView = UIStackView(arrangedSubviews: [titleTextLabel, chevronImageView])
        headerStackView.translatesAutoresizingMaskIntoConstraints = false
        headerStackView.isOpaque = false
        headerStackView.alignment = .center
        headerStackView.layoutMargins = .zero
        headerStackView.isLayoutMarginsRelativeArrangement = true

        let stackView = UIStackView(arrangedSubviews: [headerStackView, expandableTextView])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.isOpaque = false
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.layoutMargins = UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16)
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.setContentHuggingPriority(.required, for: .vertical)

        let chevronHeight = chevronImageView.heightAnchor.constraint(equalToConstant: 24)
        chevronHeight.priority = UILayoutPriority(999)

        addSubview(stackView)
        NSLayoutConstraint.activate([
            chevronImageView.widthAnchor.constraint(equalToConstant: 24),
            chevronHeight,
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func setupSubviews() {
        chevronImageView.image = .gridicon(.chevronDown)
        chevronImageView.tintColor = WPStyleGuide.cellGridiconAccessoryColor()

        titleTextLabel.textColor = .label

        let linkAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIAppColor.primary,
            .underlineStyle: 0,
            .underlineColor: UIColor.clear
        ]
        expandableTextView.linkTextAttributes = linkAttributes

        expandableTextView.delegate = self
        expandableTextView.textContainerInset = .zero
        expandableTextView.textContainer.lineFragmentPadding = 0
        expandableTextView.backgroundColor = .clear
    }
}

extension ExpandableCell: UITextViewDelegate {
    func textView(_ textView: UITextView, primaryActionFor textItem: UITextItem, defaultAction: UIAction) -> UIAction? {
        guard case let .link(URL) = textItem.content else {
            return defaultAction
        }

        return UIAction { [weak self] _ in
            self?.urlCallback?(URL)
        }
    }

    func textView(
        _ textView: UITextView,
        menuConfigurationFor textItem: UITextItem,
        defaultMenu: UIMenu
    ) -> UITextItem.MenuConfiguration? {
        if case .link = textItem.content {
            return nil
        }

        return .init(menu: defaultMenu)
    }
}
