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
    static let postCardBorderColor: UIColor = .divider

    static let separatorHeight: CGFloat = .hairlineBorderWidth

    class func applyPostCardStyle(_ cell: UITableViewCell) {
        cell.backgroundColor = .listBackground
        cell.contentView.backgroundColor = .listBackground
    }

    class func applyPostTitleStyle(_ label: UILabel) {
        label.textColor = .text
    }

    class func applyPostSnippetStyle(_ label: UILabel) {
        label.textColor = .text
    }

    class func applyPostDateStyle(_ label: UILabel) {
        configureLabelForRegularFontStyle(label)
        label.textColor = .textSubtle
    }

    class func applyPostButtonStyle(_ button: UIButton) {
        configureLabelForRegularFontStyle(button.titleLabel)
        button.setTitleColor(.textSubtle, for: .normal)
    }

    class func applyPostProgressViewStyle(_ progressView: UIProgressView) {
        progressView.trackTintColor = .divider
        progressView.progressTintColor = .primary
        progressView.tintColor = .primary
    }

    class func applyRestorePostLabelStyle(_ label: UILabel) {
        configureLabelForRegularFontStyle(label)
        label.textColor = .textSubtle
    }

    class func applyRestorePostButtonStyle(_ button: UIButton) {
        configureLabelForRegularFontStyle(button.titleLabel)
        button.setTitleColor(.accent, for: .normal)
        button.setTitleColor(.accentDark, for: .highlighted)
        button.tintColor = .accent
    }

    class func applyBorderStyle(_ view: UIView) {
        view.heightAnchor.constraint(equalToConstant: separatorHeight).isActive = true
        view.backgroundColor = postCardBorderColor
    }

    class func applyActionBarButtonStyle(_ button: UIButton) {
        button.flipInsetsForRightToLeftLayoutDirection()
        button.setImage(button.imageView?.image?.imageWithTintColor(.textSubtle), for: .normal)
        button.setTitleColor(.textSubtle, for: .normal)
        button.setTitleColor(.text, for: .highlighted)
        button.setTitleColor(.text, for: .selected)
    }

    class func insertSelectedBackgroundSubview(_ selectedBackgroundView: UIView, topMargin: CGFloat) {
        let marginMask = UIView()
        selectedBackgroundView.addSubview(marginMask)
        marginMask.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            marginMask.leadingAnchor.constraint(equalTo: selectedBackgroundView.leadingAnchor),
            marginMask.topAnchor.constraint(equalTo: selectedBackgroundView.topAnchor),
            marginMask.trailingAnchor.constraint(equalTo: selectedBackgroundView.trailingAnchor),
            marginMask.heightAnchor.constraint(equalToConstant: topMargin)
            ])
        marginMask.backgroundColor = .neutral(.shade5)
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

    static var navigationBarButtonRect = CGRect(x: 0, y: 0, width: 30, height: 30)

    static var spacingBetweeenNavbarButtons: CGFloat = 40

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
