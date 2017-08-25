extension UIButton {
    private struct Constants {
        static let labelMinHeight: CGFloat = 22.0
        static let googleIconOffset: CGFloat = -1.0
    }

    class func googleLoginButton() -> UIButton {
        let label = UILabel()
        label.isUserInteractionEnabled = false
        label.font = WPStyleGuide.mediumWeightFont(forStyle: .subheadline)

        let baseString = "Or you can {G} Log in with Google."
        setGoogleString(baseString, for: label)

        let button = UIButton()
        setupLoginButtonLayout(button, label: label)

        return button
    }

    class func setGoogleString(_ baseString: String, for label: UILabel) {
        let labelParts = baseString.components(separatedBy: "{G}")

        let firstPart = labelParts[0]
        // don't want to crash when a translation lacks "{G}"
        let lastPart = labelParts.indices.contains(1) ? labelParts[1] : ""

        let labelString = NSMutableAttributedString(string: firstPart, attributes:[NSForegroundColorAttributeName: WPStyleGuide.darkGrey()])

        if let googleIcon = UIImage(named: "google") {
            let googleAttachment = NSTextAttachment()
            googleAttachment.image = googleIcon
            googleAttachment.bounds = CGRect(x: 0.0, y: label.font.descender + Constants.googleIconOffset, width: googleIcon.size.width, height: googleIcon.size.height)
            let iconString = NSAttributedString(attachment: googleAttachment)
            labelString.append(iconString)
        }

        labelString.append(NSAttributedString(string: lastPart, attributes:[NSForegroundColorAttributeName: WPStyleGuide.wordPressBlue()]))

        label.attributedText = labelString
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

