
/**
 A Cell which includes a header label and a horizontal stack view with multiple `Item`s

     ┌───────────────┐
     │┌─────────────┐│
     ││headingLabel ││
     │└─────────────┘│
     │┌─────────────┐│
     ││┌────┐ ┌────┐││
     │││    │ │    │││
     │││item│ │item│││
     │││    │ │    │││
     ││└────┘ └────┘││
     ││gridStackView││
     │└─────────────┘│
     │ mainStackView │
     └───────────────┘
*/
class GridCell: UITableViewCell {

    struct Item {
        let image: UIImage?
        let description: String
        let action: () -> Void
    }

    lazy var headingLabel: UILabel = {
        return makeLabel(font: Appearance.headingFont, color: .textSubtle)
    }()

    /// Horizontal stack view containing `Item`s
    private lazy var gridStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        return stackView
    }()

    private lazy var mainStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [headingLabel, gridStackView])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.alignment = .leading
        stackView.axis = .vertical
        stackView.setCustomSpacing(Appearance.postHeaderSpacing, after: headingLabel)
        return stackView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(mainStackView)
        contentView.pinSubviewToSafeArea(mainStackView, insets: Appearance.mainStackViewInsets)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Configures the cell with a title and set of items.
    /// - Parameters:
    ///   - title: The title string to include in `headingLabel`
    ///   - items: The `Item`s to layout horizontally in `gridStackView`
    func configure(title: String, items: [Item]) {
        headingLabel.text = title

        let itemViews = makeViews(forItems: items)
        gridStackView.addArrangedSubviews(itemViews)
        gridStackView.addInterItemSpacing(Appearance.gridIteminterItemSpacing)
    }

    /// Creates a view for `Item`s (see `makeGridButton`)
    /// - Parameter items: The items to populate the Item Grid Buttons
    private func makeViews(forItems items: [Item]) -> [UIView] {
        return items.map { item in
            let button = makeGridButton(image: item.image, action: item.action)
            button.accessibilityLabel = item.description
            return button
        }
    }
}

private extension UIStackView {
    /// Adds spacing after each view in `arrangedSubviews`, except for the last one.
    /// - Parameter spacing: The spacing to apply between arranged subviews.
    func addInterItemSpacing(_ spacing: CGFloat) {
        let nextToLast = arrangedSubviews.index(before: arrangedSubviews.endIndex)
        arrangedSubviews[arrangedSubviews.startIndex..<nextToLast].forEach() { view in
            setCustomSpacing(spacing, after: view)
        }
    }
}

// MARK: Helpers
private extension GridCell {

    /// Creates a label with the provided font and text color.
    /// - Parameters:
    ///   - font: The font to be used for the label.
    ///   - color: The color to use for the label's `textColor`.
    /// - Returns: The configured label.
    func makeLabel(font: UIFont, color: UIColor? = nil) -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.font = font
        if let color = color {
            label.textColor = color
        }
        return label
    }

    /// Creates a button to show a large image + perform an action on `touchUpInside`.
    /// - Parameters:
    ///   - image: The image to show in the button. The button will be constrained to match the image's size.
    ///   - action: An action to perform when the button is tapped.
    /// - Returns: The configured button.
    func makeGridButton(image: UIImage?, action: @escaping () -> Void) -> UIButton {
        let button = ClosureButton(frame: .zero, closure: action)
        button.setImage(image, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false

        let imageWidth = image?.size.width ?? 0
        let imageHeight = image?.size.height ?? 0
        button.addConstraints([
            // Width attempts to match the image size but can scale down if it doesn't fit. (Narrowest iPad split screen + iPhone SE)
            button.widthAnchor.constraint(lessThanOrEqualToConstant: imageWidth),
            // Height is scaled to the same aspect ratio as the image to scale with width changes.
            button.heightAnchor.constraint(equalTo: button.widthAnchor, multiplier: imageHeight/imageWidth),
        ])
        return button
    }
}

// MARK: - Appearance
private extension GridCell {
    enum Appearance {
        // heading
        static let headingFont = UIFont(descriptor: UIFontDescriptor.preferredFontDescriptor(withTextStyle: .subheadline), size: 17)

        // sub-heading
        static let subHeadingFont = UIFont(descriptor: UIFontDescriptor.preferredFontDescriptor(withTextStyle: .subheadline), size: 15)

        // main stack view
        static let mainStackViewInsets = UIEdgeInsets(top: 0, left: 0, bottom: 24, right: 0)

        /// The spacing below `headingLabel`
        static let postHeaderSpacing: CGFloat = 8

        // grid stack view
        static let gridIteminterItemSpacing: CGFloat = 8
    }
}

//TODO: Remove with iOS 14
class ClosureButton: UIButton {
    let closure: () -> Void

    init(frame: CGRect, closure: @escaping () -> Void) {
        self.closure = closure
        super.init(frame: frame)
        self.addTarget(self, action: #selector(tapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func tapped() {
        closure()
    }
}
