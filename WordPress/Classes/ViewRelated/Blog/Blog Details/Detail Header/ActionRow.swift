class ActionButton: UIView {

    private enum Constants {
        static let maxButtonSize: CGFloat = 56
        static let spacing: CGFloat = 8
        static let borderColor = UIColor.quickActionButtonBorder
        static let backgroundColor = UIColor.quickActionButtonBackground
        static let selectedBackgroundColor = UIColor.quickActionSelectedBackground
        static let iconColor = UIColor.listIcon
    }

    private let button: UIButton = {
        let button = RoundedButton(type: .custom)
        button.isCircular = true
        button.borderColor = Constants.borderColor
        button.borderWidth = 1
        button.backgroundColor = Constants.backgroundColor
        button.selectedBackgroundColor = Constants.selectedBackgroundColor
        button.tintColor = Constants.iconColor
        button.imageView?.contentMode = .center
        button.imageView?.clipsToBounds = false
        return button
    }()

    private let titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
        titleLabel.textAlignment = .center
        titleLabel.adjustsFontForContentSizeCategory = true
        return titleLabel
    }()

    private var callback: (() -> Void)?

    convenience init(image: UIImage, title: String, tapped: @escaping () -> Void) {

        self.init(frame: .zero)

        button.setImage(image, for: .normal)
        titleLabel.text = title

        button.accessibilityLabel = title
        accessibilityElements = [button]

        let stackView = UIStackView(arrangedSubviews: [
            button,
            titleLabel
        ])
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = Constants.spacing
        stackView.axis = .vertical

        callback = tapped
        button.addTarget(self, action: #selector(ActionButton.tapped), for: .touchUpInside)

        NSLayoutConstraint.activate([
            button.heightAnchor.constraint(equalTo: button.widthAnchor, multiplier: 1),
            button.heightAnchor.constraint(lessThanOrEqualToConstant: Constants.maxButtonSize)
        ])

        addSubview(stackView)

        pinSubviewToAllEdges(stackView)
    }

    @objc func tapped() {
        callback?()
    }
}

class ActionRow: UIStackView {

    enum Constants {
        static let minimumSpacing: CGFloat = 8
    }

    struct Item {
        let image: UIImage
        let title: String
        let tapped: () -> Void
    }

    convenience init(items: [Item]) {

        let buttons = items.map({ item in
            return ActionButton(image: item.image, title: item.title, tapped: item.tapped)
        })

        self.init(arrangedSubviews: buttons)

        distribution = .equalCentering
        spacing = Constants.minimumSpacing
        translatesAutoresizingMaskIntoConstraints = false
        refreshStackViewVisibility()
    }

    // MARK: - Accessibility

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        refreshStackViewVisibility()
    }

    private func refreshStackViewVisibility() {
        for view in arrangedSubviews {
            if traitCollection.preferredContentSizeCategory.isAccessibilityCategory {
                view.isHidden = true
            } else {
                view.isHidden = false
            }
        }
    }
}
