
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
     │││    │ │    │││
     ││└────┘ └────┘││
     ││gridStackView││
     │└─────────────┘│
     │ mainStackView │
     └───────────────┘
*/
class GridCell: UITableViewCell {

    struct Item {
        let image: UIImage
        let description: String
        let action: () -> Void
    }

    // MARK: - View elements
    lazy var headingLabel: UILabel = {
        return makeLabel(font: Appearance.headingFont, color: .textSubtle)
    }()

    /// Horizontal stack view containing `Item`s
    private lazy var gridStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.distribution = .equalCentering
        return stackView
    }()

    private lazy var mainStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [headingLabel, gridStackView])
        stackView.translatesAutoresizingMaskIntoConstraints = false
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

        let views: [UIView] = items.map { item in
            let button = makeGridButton(image: item.image, action: item.action)
            let label = makeLabel(font: Appearance.subHeadingFont, color: .textSubtle)
            label.text = item.description
            let stackView = makeGridStackView(button: button, label: label)
            return stackView
        }

        gridStackView.addArrangedSubviews(views)
        let nextToLast = views.index(before: views.endIndex)
        views[views.startIndex..<nextToLast].forEach() { view in
            gridStackView.setCustomSpacing(Appearance.gridIteminterItemSpacing, after: view)
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
    func makeGridButton(image: UIImage, action: @escaping () -> Void) -> UIButton {
        let button: UIButton
        if #available(iOS 14.0, *) {
            button = UIButton(type: .custom, primaryAction: UIAction(handler: { _ in
                action()
            }))
        } else {
            button = ClosureButton(frame: .zero, closure: action)
        }
        button.setImage(image, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addConstraints([
            button.widthAnchor.constraint(equalToConstant: image.size.width),
            button.heightAnchor.constraint(equalToConstant: image.size.height)
        ])
        return button
    }

    /**
    Creates a vertical stack view with `button` on top and `label` on bottom.

         ┌──────────┐
         │          │
         │          │
         │  button  │
         │          │
         │          │
         │          │
         └──────────┘
        gridButtonLabelSpacing
         ┌──────────┐
         │  label   │
         └──────────┘

    - Parameters:
        - button: The button to go on the top of the stack view.
        - label: The label to go on the bottom of the stack view.
    - Returns: The resulting stack view.
     */
    func makeGridStackView(button: UIView, label: UIView) -> UIStackView {
        let stackView = UIStackView(arrangedSubviews: [
            button,
            label
        ])
        stackView.alignment = .top
        stackView.setCustomSpacing(Appearance.gridButtonLabelSpacing, after: button)
        stackView.axis = .vertical
        stackView.distribution = .fill
        return stackView
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
        static let imageTextSpacing: CGFloat = 16
        static let mainStackViewInsets = UIEdgeInsets(top: 0, left: 0, bottom: 24, right: 0)

        /// The spacing below `headingLabel`
        static let postHeaderSpacing: CGFloat = 8

        // grid stack view
        static let gridButtonLabelSpacing: CGFloat = 4
        static let gridIteminterItemSpacing: CGFloat = 8
    }
}

//TODO: Remove with iOS 14
class ClosureButton: UIButton {
    let closure: () -> Void

    init(frame: CGRect, closure: @escaping () -> Void) {
        self.closure = closure
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
