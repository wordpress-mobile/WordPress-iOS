/// A WPStyleGuide extension with styles and methods specific to the Posts feature.
///
extension WPStyleGuide {

    // MARK: - Card View Styles
    class func postCardBorderColor() -> UIColor {
        return UIColor(fromRGBAColorWithRed: 215.0, green: 227.0, blue: 235.0, alpha: 1.0)
    }

    class func applyPostCardStyle(_ cell: UITableViewCell) {
        cell.backgroundColor = greyLighten30()
        cell.contentView.backgroundColor = greyLighten30()
    }

    class func applyPostTitleStyle(_ label: UILabel) {
        label.textColor = darkGrey()
    }

    class func applyPostSnippetStyle(_ label: UILabel) {
        label.textColor = darkGrey()
    }

    class func applyPostDateStyle(_ label: UILabel) {
        configureLabelForRegularFontStyle(label)
        label.textColor = grey()
    }

    class func applyPostButtonStyle(_ button: UIButton) {
        configureLabelForRegularFontStyle(button.titleLabel)
        button.setTitleColor(grey(), for: .normal)
    }

    class func applyPostProgressViewStyle(_ progressView: UIProgressView) {
        progressView.trackTintColor = greyLighten20()
        progressView.progressTintColor = mediumBlue()
        progressView.tintColor = mediumBlue()
    }

    class func applyRestorePostLabelStyle(_ label: UILabel) {
        configureLabelForRegularFontStyle(label)
        label.textColor = grey()
    }

    class func applyRestorePostButtonStyle(_ button: UIButton) {
        configureLabelForRegularFontStyle(button.titleLabel)
        button.setTitleColor(wordPressBlue(), for: .normal)
        button.setTitleColor(darkBlue(), for: .highlighted)
    }

    // MARK: - Font Styles

    static func configureLabelForRegularFontStyle(_ label: UILabel?) {
        guard let label = label else {
            return
        }

        WPStyleGuide.configureLabel(label, textStyle: .subheadline)
    }

}
