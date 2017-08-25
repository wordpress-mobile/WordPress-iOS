extension UIButton {
    private struct Constants {
        static let labelMinHeight: CGFloat = 22.0
    }

    class func googleLoginButton() -> UIButton {
        let label = UILabel()

        let baseString = "Or you can {G} Login with Google."
        let buttonString = processGoogleString(baseString)


        label.attributedText = buttonString
        label.isUserInteractionEnabled = false
        label.font = WPStyleGuide.mediumWeightFont(forStyle: .subheadline)


        let button = UIButton()

        setupLoginButtonLayout(button, label: label)

        return button
    }

    class func processGoogleString(_ baseString: String) -> NSAttributedString {
        let parts = baseString.components(separatedBy: "{G}")

        let firstPart = parts[0]
        // don't want to crash when a translation lacks "{G}"
        let lastPart = parts.indices.contains(1) ? parts[1] : ""

        let tempIcon = UIImage(named: "google")
        let iconAttachment = NSTextAttachment()
        iconAttachment.image = tempIcon
        let attachedString = NSAttributedString(attachment: iconAttachment)

        let buttonString = NSMutableAttributedString(string: firstPart, attributes:[NSForegroundColorAttributeName: WPStyleGuide.darkGrey()])
        buttonString.append(attachedString)
        buttonString.append(NSAttributedString(string: lastPart, attributes:[NSForegroundColorAttributeName: WPStyleGuide.wordPressBlue()]))

        return buttonString
    }

    class func loginTextButton(text: NSAttributedString) -> UIButton {
        let label = UILabel()
        label.attributedText = text
        label.isUserInteractionEnabled = false
        let button = UIButton()

        setupLoginButtonLayout(button, label: label)

        return button
    }

    private class func setupLoginButtonLayout(_ button: UIButton, label: UILabel) {
        button.translatesAutoresizingMaskIntoConstraints = false
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        button.addSubview(label)

        button.addConstraints([
            button.topAnchor.constraint(equalTo: label.topAnchor),
            button.leftAnchor.constraint(equalTo: label.leftAnchor),
            button.rightAnchor.constraint(equalTo: label.rightAnchor),
            button.heightAnchor.constraint(equalTo: label.heightAnchor)
            ])
        label.addConstraints([
            label.heightAnchor.constraint(greaterThanOrEqualToConstant: Constants.labelMinHeight)
            ])
    }
}

