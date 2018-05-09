import Foundation

/// This class will display a small view prompt to gather info about the users'
/// current feelings regarding the app.
/// This class is based on ABXPromptView of [AppBotX](https://github.com/appbot/appbotx)
///
protocol AppFeedbackPromptViewDelegate: class {
    func likedApp()
    func dislikedApp()
    func gatherFeedback()
    func dismissPrompt()
}

class AppFeedbackPromptView: UIView {
    let label = UILabel()
    let leftButton = RoundedButton()
    let rightButton = RoundedButton()
    let buttonStack = UIStackView()
    var onRequestingFeedback = false
    var constraintsAdded = false

    weak var delegate: AppFeedbackPromptViewDelegate?

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
        label.text = NSLocalizedString("What do you think about WordPress?",
                                       comment: "This is the string we display when prompting the user to review the app")
        addSubview(label)

        // Stack O'Buttons
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        buttonStack.axis = .horizontal
        buttonStack.spacing = 10.0
        addSubview(buttonStack)

        // Yes Button
        leftButton.translatesAutoresizingMaskIntoConstraints = false
        leftButton.backgroundColor = UIColor(red: 0.0, green: 170/255.0, blue: 220/255.0, alpha: 1.0)
        leftButton.tintColor = .white
        leftButton.setTitle(NSLocalizedString("I Like It",
                                              comment: "This is one of the buttons we display inside of the prompt to review the app"),
                            for: .normal)
        leftButton.setTitleColor(UIColor.white, for: .normal)
        leftButton.titleLabel?.font = textFont
        leftButton.addTarget(self, action: #selector(self.leftButtonTouched), for: .touchUpInside)
        buttonStack.addArrangedSubview(leftButton)

        // Could be Better Button
        rightButton.translatesAutoresizingMaskIntoConstraints = false
        rightButton.backgroundColor = UIColor(red: 144/255.0, green: 174/255.0, blue: 194/255.0, alpha: 1.0)
        rightButton.tintColor = .white
        rightButton.setTitle(NSLocalizedString("Could Be Better",
                                               comment: "This is one of the buttons we display inside of the prompt to review the app"),
                             for: .normal)
        rightButton.setTitleColor(UIColor.white, for: .normal)
        rightButton.titleLabel?.font = textFont
        rightButton.addTarget(self, action: #selector(self.rightButtonTouched), for: .touchUpInside)
        buttonStack.addArrangedSubview(rightButton)

        setNeedsUpdateConstraints()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        self.buttonStack.axis = .horizontal
        self.buttonStack.isLayoutMarginsRelativeArrangement = true

        // measure the width of the view with the new font sizes to see if the buttons are too wide.
        leftButton.updateFontSizeToMatchSystem()
        rightButton.updateFontSizeToMatchSystem()
        let newLayoutSize = systemLayoutSizeFitting(UILayoutFittingCompressedSize)

        // if the new width is too wide, change the axis of the stack view
        if newLayoutSize.width > UIScreen.main.bounds.size.width {
            self.buttonStack.axis = .vertical
            self.setNeedsLayout()
        }

    }

    override func updateConstraints() {
        setupConstraints()
        super.updateConstraints()
    }

    func setupConstraints() {
        guard constraintsAdded == false else {
            return
        }
        constraintsAdded = true

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

    @objc func leftButtonTouched() {
        if onRequestingFeedback {
            delegate?.gatherFeedback()
        } else {
            delegate?.likedApp()
            leftButton.isHidden = true
            rightButton.isHidden = true
            UIView.animate(withDuration: 0.3, animations: {() -> Void in
                self.label.text = NSLocalizedString("Great!\n We love to hear from happy users \n😁",
                                                    comment: "This is the text we display to the user after they've indicated they like the app")
            })
        }
    }

    @objc func rightButtonTouched() {
        if onRequestingFeedback {
            delegate?.dismissPrompt()
        } else {
            delegate?.dislikedApp()
            onRequestingFeedback = true
            UIView.animate(withDuration: 0.3, animations: {() -> Void in
                self.label.text = NSLocalizedString("Could you tell us how we could improve?",
                                                    comment: "This is the text we display to the user when we ask them for a review and they've indicated they don't like the app")
                self.leftButton.setTitle(NSLocalizedString("Send Feedback",
                                                           comment: "This is one of the buttons we display when prompting the user for a review"),
                                         for: .normal)
                self.rightButton.setTitle(NSLocalizedString("No Thanks",
                                                            comment: "This is one of the buttons we display when prompting the user for a review"),
                                          for: .normal)
            })
        }
    }

    /// MARK: - Static Constants

    // these values based on Zeplin mockups
    private struct LayoutConstants {
        static let labelMinimumHeight: CGFloat = 18.0
        static let basePadding: CGFloat = 15.0
        static let labelHorizontalPadding: CGFloat = 37.0
    }
}
