/// A WPStyleGuide extension with styles and methods specific to the Posts feature.
///
extension WPStyleGuide {

    // MARK: - General Posts Styles

    class func applyPostTitleStyle(_ title: String, into label: UILabel) {
        label.attributedText = NSAttributedString(string: title, attributes: WPStyleGuide.postCardTitleAttributes)
        label.lineBreakMode = .byTruncatingTail
    }

    class func applyPostSnippetStyle(_ title: String, into label: UILabel) {
        label.attributedText = NSAttributedString(string: title, attributes: WPStyleGuide.postCardSnippetAttributes)
        label.lineBreakMode = .byTruncatingTail
    }

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

    class func applyBorderStyle(_ view: UIView) {
        view.heightAnchor.constraint(equalToConstant: 1.0 / UIScreen.main.scale).isActive = true
        view.backgroundColor = postCardBorderColor()
    }

    class func applyActionBarButtonStyle(_ button: UIButton) {
        button.flipInsetsForRightToLeftLayoutDirection()
        button.setImage(button.imageView?.image?.imageWithTintColor(grey()), for: .normal)
        button.setTitleColor(grey(), for: .normal)
        button.setTitleColor(darkGrey(), for: .highlighted)
        button.setTitleColor(darkGrey(), for: .selected)
    }

    class func insertSelectedBackgroundSubview(_ selectedBackgroundView: UIView, topMargin: CGFloat) {
        let marginMask = UIView()
        selectedBackgroundView.addSubview(marginMask)
        marginMask.translatesAutoresizingMaskIntoConstraints = false
        marginMask.leadingAnchor.constraint(equalTo: selectedBackgroundView.leadingAnchor).isActive = true
        marginMask.topAnchor.constraint(equalTo: selectedBackgroundView.topAnchor).isActive = true
        marginMask.trailingAnchor.constraint(equalTo: selectedBackgroundView.trailingAnchor).isActive = true
        marginMask.heightAnchor.constraint(equalToConstant: topMargin).isActive = true
        marginMask.backgroundColor = greyLighten30()
    }

    // MARK: - Attributed String Attributes

    class var postCardTitleAttributes: [NSAttributedString.Key: Any] {
        let font = notoBoldFontForTextStyle(.headline)
        let lineHeight = 1.4 * font.pointSize
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = lineHeight
        paragraphStyle.maximumLineHeight = lineHeight
        return [.paragraphStyle: paragraphStyle, .font: font]
    }

    class var postCardSnippetAttributes: [NSAttributedString.Key: Any] {
        let textStyle: UIFont.TextStyle = UIDevice.isPad() ? .callout : .subheadline
        let font = notoFontForTextStyle(textStyle)
        let lineHeight = 1.6 * font.pointSize
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = lineHeight
        paragraphStyle.maximumLineHeight = lineHeight
        return [.paragraphStyle: paragraphStyle, .font: font]
    }

    // MARK: - Nav Bar Styles

    class var navigationBarButtonRect: CGRect {
        return CGRect(x: 0, y: 0, width: 30, height: 30)
    }

    class var spacingBetweeenNavbarButtons: CGFloat {
        return 40
    }

    class func buttonForBar(with image: UIImage,
                            target: Any?, selector: Selector) -> WPButtonForNavigationBar {
        let button = WPButtonForNavigationBar(frame: navigationBarButtonRect)
        button.tintColor = .white
        button.setImage(image, for: .normal)
        button.addTarget(target, action: selector, for: .touchUpInside)
        button.removeDefaultLeftSpacing = true
        button.removeDefaultRightSpacing = true
        button.rightSpacing = spacingBetweeenNavbarButtons / 2
        button.leftSpacing = spacingBetweeenNavbarButtons / 2
        return button
    }

    // MARK: - Font Styles

    static func configureLabelForRegularFontStyle(_ label: UILabel?) {
        guard let label = label else {
            return
        }

        WPStyleGuide.configureLabel(label, textStyle: .subheadline)
    }

}
