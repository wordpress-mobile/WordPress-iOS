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
        button.setTitleColor(.primary, for: .normal)
        button.setTitleColor(.primaryDark, for: .highlighted)
        button.tintColor = .primary
    }

    class func applyBorderStyle(_ view: UIView) {
        view.updateConstraint(for: .height, withRelation: .equal, setConstant: separatorHeight, setActive: true)
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

    // MARK: - Font Styles

    static func configureLabelForRegularFontStyle(_ label: UILabel?) {
        guard let label = label else {
            return
        }

        WPStyleGuide.configureLabel(label, textStyle: .subheadline)
    }

}
