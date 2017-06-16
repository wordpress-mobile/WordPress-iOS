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
    let container = UIView(frame: containerFrame)
    let label = UILabel(frame: labelFrame)
    let leftButton = UIButton(type: .custom)
    let rightButton = UIButton(type: .custom)
    var onRequestingFeedback: Bool = false

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
        container.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin]
        container.backgroundColor = UIColor.clear
        addSubview(container)
        container.center = CGPoint(x: bounds.midX, y: bounds.midY)

        let textFont = WPStyleGuide.fontForTextStyle(.subheadline)

        label.textColor = UIColor(red: 50/255.0, green: 65/255.0, blue: 85/255.0, alpha: 1.0)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.font = textFont
        label.text = NSLocalizedString("What do you think about WordPress?",
                                       comment: "This is the string we display when prompting the user to review the app")
        container.addSubview(label)

        leftButton.frame = CGRect(x: container.bounds.midX - 135.0, y: 50.0, width: 130.0, height: 30.0)
        leftButton.backgroundColor = UIColor(red: 0.0, green: 170/255.0, blue: 220/255.0, alpha: 1.0)
        leftButton.layer.cornerRadius = 4
        leftButton.layer.masksToBounds = true
        leftButton.setTitle(NSLocalizedString("I Like It",
                                              comment: "This is one of the buttons we display inside of the prompt to review the app"),
                            for: .normal)
        leftButton.setTitleColor(UIColor.white, for: .normal)
        leftButton.titleLabel?.font = textFont
        leftButton.addTarget(self, action: #selector(self.leftButtonTouched), for: .touchUpInside)
        container.addSubview(leftButton)

        rightButton.frame = CGRect(x: container.bounds.midX + 5, y: 50.0, width: 130.0, height: 30.0)
        rightButton.backgroundColor = UIColor(red: 144/255.0, green: 174/255.0, blue: 194/255.0, alpha: 1.0)
        rightButton.layer.cornerRadius = 4
        rightButton.layer.masksToBounds = true
        rightButton.setTitle(NSLocalizedString("Could Be Better",
                                               comment: "This is one of the buttons we display inside of the prompt to review the app"),
                             for: .normal)
        rightButton.setTitleColor(UIColor.white, for: .normal)
        rightButton.titleLabel?.font = textFont
        rightButton.addTarget(self, action: #selector(self.rightButtonTouched), for: .touchUpInside)
        container.addSubview(rightButton)
    }

    func leftButtonTouched() {
        if onRequestingFeedback {
            delegate?.gatherFeedback()
        } else {
            delegate?.likedApp()
            leftButton.isHidden = true
            rightButton.isHidden = true
            label.frame = AppFeedbackPromptView.labelBigFrame
            UIView.animate(withDuration: 0.3, animations: {() -> Void in
                self.label.text = NSLocalizedString("Great!\n We love to hear from happy users \n😁",
                                                    comment: "This is the text we display to the user after they've indicated they like the app")
            })
        }
    }

    func rightButtonTouched() {
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

    fileprivate static let containerFrame = CGRect(x: 0.0, y: 0.0, width: 280.0, height: 100.0)
    fileprivate static let labelFrame = CGRect(x: 0.0, y: 0.0, width: containerFrame.width, height: 52.0)
    fileprivate static let labelBigFrame = CGRect(x: 0.0, y: 0.0, width: containerFrame.width, height: containerFrame.height)
}
