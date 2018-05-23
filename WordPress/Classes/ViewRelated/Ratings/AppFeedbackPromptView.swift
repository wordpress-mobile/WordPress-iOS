import Foundation

/// This class will display a small view prompt to gather info about the users'
/// current feelings regarding the app.
/// This class is based on ABXPromptView of [AppBotX](https://github.com/appbot/appbotx)
///
class AppFeedbackPromptView: UIView {
    private let label = UILabel()
    private let leftButton = RoundedButton()
    private let rightButton = RoundedButton()
    private let buttonStack = UIStackView()
    private var onRequestingFeedback = false

    /// MARK: - UIView's Methods

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupSubviews()
    }

    /// MARK: - Helpers

    fileprivate func setupSubviews() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = UIColor.clear

        let textFont = WPStyleGuide.fontForTextStyle(.subheadline)

        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor(red: 50/255.0, green: 65/255.0, blue: 85/255.0, alpha: 1.0)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.font = textFont

        addSubview(label)

        // Stack O'Buttons
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        buttonStack.axis = .horizontal
        buttonStack.spacing = LayoutConstants.buttonSpacing
        addSubview(buttonStack)

        // Yes Button
        leftButton.translatesAutoresizingMaskIntoConstraints = false
        leftButton.backgroundColor = UIColor(red: 0.0, green: 170/255.0, blue: 220/255.0, alpha: 1.0)
        leftButton.tintColor = .white
        leftButton.setTitleColor(UIColor.white, for: .normal)
        leftButton.titleLabel?.font = textFont
        buttonStack.addArrangedSubview(leftButton)

        // Could be Better Button
        rightButton.translatesAutoresizingMaskIntoConstraints = false
        rightButton.backgroundColor = UIColor(red: 144/255.0, green: 174/255.0, blue: 194/255.0, alpha: 1.0)
        rightButton.tintColor = .white
        rightButton.setTitleColor(UIColor.white, for: .normal)
        rightButton.titleLabel?.font = textFont
        buttonStack.addArrangedSubview(rightButton)

        setupConstraints()
    }

    func setupHeading(_ title: String) {
        label.text = title
    }

    func setupYesButton(title: String, tapHandler: @escaping (UIControl) -> Void) {
        leftButton.removeTarget(nil, action: nil, for: .touchUpInside)
        leftButton.setTitle(title, for: .normal)
        leftButton.on(.touchUpInside, call: tapHandler)
    }

    func setupNoButton(title: String, tapHandler: @escaping (UIControl) -> Void) {
        rightButton.removeTarget(nil, action: nil, for: .touchUpInside)
        rightButton.setTitle(title, for: .normal)
        rightButton.on(.touchUpInside, call: tapHandler)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        buttonStack.axis = .horizontal
        buttonStack.isLayoutMarginsRelativeArrangement = true

        // measure the width of the view with the new font sizes to see if the buttons are too wide.
        leftButton.updateFontSizeToMatchSystem()
        rightButton.updateFontSizeToMatchSystem()
        let newLayoutSize = systemLayoutSizeFitting(UILayoutFittingCompressedSize)

        // if the new width is too wide, change the axis of the stack view
        guard let superviewSize = superview?.bounds.size else {
            return
        }

        if newLayoutSize.width > superviewSize.width {
            buttonStack.axis = .vertical
            setNeedsLayout()
        }
    }

    func setupConstraints() {
        addConstraints([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.topAnchor.constraint(equalTo: topAnchor, constant: LayoutConstants.basePadding),
            label.bottomAnchor.constraint(equalTo: buttonStack.topAnchor, constant: -LayoutConstants.basePadding),
            label.heightAnchor.constraint(greaterThanOrEqualToConstant: LayoutConstants.labelMinimumHeight),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: LayoutConstants.labelHorizontalPadding),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -LayoutConstants.labelHorizontalPadding),

            // position the button stack view
            bottomAnchor.constraint(greaterThanOrEqualTo: buttonStack.bottomAnchor, constant: LayoutConstants.basePadding),
            buttonStack.centerXAnchor.constraint(equalTo: centerXAnchor),

            // make sure the primary/yes button is always at least as big as the cancel/no button
            leftButton.widthAnchor.constraint(greaterThanOrEqualTo: rightButton.widthAnchor),

            // ensure the buttons have horizontal padding from the sides of the view
            leftButton.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: LayoutConstants.basePadding),
            trailingAnchor.constraint(greaterThanOrEqualTo: rightButton.trailingAnchor, constant: LayoutConstants.basePadding)
        ])
    }

    func showBigHeading(title: String) {
        leftButton.isHidden = true
        rightButton.isHidden = true
        UIView.animate(withDuration: 0.3) {
            self.label.text = title
        }
    }

    /// MARK: - Static Constants

    // these values based on Zeplin mockups
    private struct LayoutConstants {
        static let labelMinimumHeight: CGFloat = 18.0
        static let basePadding: CGFloat = 15.0
        static let labelHorizontalPadding: CGFloat = 37.0
        static let buttonSpacing: CGFloat = 10.0
    }
}
