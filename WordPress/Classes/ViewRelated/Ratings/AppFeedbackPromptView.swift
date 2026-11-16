import UIKit
import WordPressUI

/// This class will display a small view prompt to gather info about the users'
/// current feelings regarding the app.
/// This class is based on ABXPromptView of [AppBotX](https://github.com/appbot/appbotx)
///
class AppFeedbackPromptView: UIView {
    private let label = UILabel()
    private let leftButton = RoundedButton()
    private let rightButton = RoundedButton()
    private let buttonStack = UIStackView()
    private var lastAvailableWidth: CGFloat?
    /// Active while the buttons are stacked, so they span the same width as the text above them.
    private var stackedWidthConstraints: [NSLayoutConstraint] = []

    // MARK: - UIView's Methods

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupSubviews()
    }

    // MARK: - Helpers

    fileprivate func setupSubviews() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = UIColor.clear

        let textFont = WPStyleGuide.fontForTextStyle(.subheadline)

        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.font = textFont

        addSubview(label)

        // Stack O'Buttons
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        buttonStack.axis = .horizontal
        buttonStack.spacing = LayoutConstants.buttonSpacing
        buttonStack.isLayoutMarginsRelativeArrangement = true
        // Margins taken from the safe area change as the row moves. Where the row overlaps a horizontal
        // inset (the side strip on the iPhone Duo's outer screen), it never settles and layout loops.
        buttonStack.insetsLayoutMarginsFromSafeArea = false
        addSubview(buttonStack)

        // Yes Button
        leftButton.translatesAutoresizingMaskIntoConstraints = false
        leftButton.backgroundColor = UIAppColor.primary
        leftButton.tintColor = .white
        leftButton.setTitleColor(.white, for: .normal)
        leftButton.titleLabel?.font = textFont
        leftButton.accessibilityIdentifier = "yes-button"
        buttonStack.addArrangedSubview(leftButton)

        // Could improve Button
        rightButton.translatesAutoresizingMaskIntoConstraints = false
        rightButton.backgroundColor = UIColor(light: .white, dark: .systemGray5)
        rightButton.borderWidth = 1.0
        rightButton.borderColor = .systemGray3
        rightButton.tintColor = .label
        rightButton.setTitleColor(.label, for: .normal)
        rightButton.titleLabel?.font = textFont
        rightButton.accessibilityIdentifier = "no-button"
        buttonStack.addArrangedSubview(rightButton)

        setupConstraints()

        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (self: Self, _: UITraitCollection) in
            self.evaluateStackAxisMode()
        }
    }

    override func layoutSubviews() {
        let availableWidth = bounds.inset(by: safeAreaInsets).width
        if availableWidth != lastAvailableWidth {
            lastAvailableWidth = availableWidth
            evaluateStackAxisMode()
        }
        super.layoutSubviews()
    }

    func setupHeading(_ title: String) {
        label.text = title
    }

    func setupYesButton(title: String, tapHandler: @escaping (UIControl) -> Void) {
        leftButton.removeTarget(nil, action: nil, for: .touchUpInside)
        leftButton.setTitle(title, for: .normal)
        leftButton.on(.touchUpInside, call: tapHandler)
        evaluateStackAxisMode()
    }

    func setupNoButton(title: String, tapHandler: @escaping (UIControl) -> Void) {
        rightButton.removeTarget(nil, action: nil, for: .touchUpInside)
        rightButton.setTitle(title, for: .normal)
        rightButton.on(.touchUpInside, call: tapHandler)
        evaluateStackAxisMode()
    }

    /// Stacks the buttons vertically when they don't fit side by side inside the safe area.
    private func evaluateStackAxisMode() {
        leftButton.updateFontSizeToMatchSystem()
        rightButton.updateFontSizeToMatchSystem()
        // Several lines of large centered text are hard to read, so align it like body text.
        label.textAlignment = traitCollection.preferredContentSizeCategory.isAccessibilityCategory ? .natural : .center

        let availableWidth = bounds.inset(by: safeAreaInsets).width
        guard availableWidth > 0 else {
            return
        }

        // The yes button is at least as wide as the no button (see `setupConstraints`).
        // Measure the titles on one line. A button that has already wrapped its title reports the wrapped width.
        let unlimited = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        let leftWidth = leftButton.sizeThatFits(unlimited).width
        let rightWidth = rightButton.sizeThatFits(unlimited).width
        let rowWidth = max(leftWidth, rightWidth) + LayoutConstants.buttonSpacing + rightWidth
        let axis: NSLayoutConstraint.Axis =
            rowWidth + 2 * LayoutConstants.basePadding > availableWidth ? .vertical : .horizontal

        if buttonStack.axis != axis {
            buttonStack.axis = axis
            updateLayout(for: axis)
            setNeedsLayout()
        }
    }

    private func updateLayout(for axis: NSLayoutConstraint.Axis) {
        let isStacked = axis == .vertical
        for button in [leftButton, rightButton] {
            button.verticalEdgeInset =
                isStacked ? LayoutConstants.stackedButtonVerticalInset : LayoutConstants.buttonVerticalInset
        }
        if isStacked {
            NSLayoutConstraint.activate(stackedWidthConstraints)
        } else {
            NSLayoutConstraint.deactivate(stackedWidthConstraints)
        }
    }

    func setupConstraints() {
        let safeArea = safeAreaLayoutGuide
        stackedWidthConstraints = [
            buttonStack.leadingAnchor.constraint(equalTo: label.leadingAnchor),
            buttonStack.trailingAnchor.constraint(equalTo: label.trailingAnchor)
        ]
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor, constant: LayoutConstants.basePadding),
            label.bottomAnchor.constraint(equalTo: buttonStack.topAnchor, constant: -LayoutConstants.basePadding),
            label.heightAnchor.constraint(greaterThanOrEqualToConstant: LayoutConstants.labelMinimumHeight),
            label.leadingAnchor.constraint(
                equalTo: safeArea.leadingAnchor,
                constant: LayoutConstants.labelHorizontalPadding
            ),
            label.trailingAnchor.constraint(
                equalTo: safeArea.trailingAnchor,
                constant: -LayoutConstants.labelHorizontalPadding
            ),

            // position the button stack view
            bottomAnchor.constraint(
                greaterThanOrEqualTo: buttonStack.bottomAnchor,
                constant: LayoutConstants.basePadding
            ),
            buttonStack.centerXAnchor.constraint(equalTo: safeArea.centerXAnchor),

            // make sure the primary/yes button is always at least as big as the cancel/no button
            leftButton.widthAnchor.constraint(greaterThanOrEqualTo: rightButton.widthAnchor),

            // ensure the buttons have horizontal padding from the sides of the view
            leftButton.leadingAnchor.constraint(
                greaterThanOrEqualTo: safeArea.leadingAnchor,
                constant: LayoutConstants.basePadding
            ),
            safeArea.trailingAnchor.constraint(
                greaterThanOrEqualTo: rightButton.trailingAnchor,
                constant: LayoutConstants.basePadding
            )
        ])
    }

    func showBigHeading(title: String) {
        leftButton.isHidden = true
        rightButton.isHidden = true
        UIView.animate(withDuration: 0.3) {
            self.label.text = title
        }
    }

    // MARK: - Static Constants

    // these values based on Zeplin mockups
    private struct LayoutConstants {
        static let labelMinimumHeight: CGFloat = 18.0
        static let basePadding: CGFloat = 15.0
        // Lines the text up with the section titles in the list below.
        static let labelHorizontalPadding: CGFloat = 20.0
        static let buttonSpacing: CGFloat = 10.0
        static let buttonVerticalInset: CGFloat = 5.0
        static let stackedButtonVerticalInset: CGFloat = 12.0
    }
}
