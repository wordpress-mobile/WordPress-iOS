import UIKit

final class DashboardStatsNudgeButton: MultilineButton {

    var onTap: (() -> Void)?

    convenience init(title: String, hint: String) {
        self.init(frame: .zero)

        setTitle(title: title, hint: hint)
    }

    // MARK: - Overrides

    override var intrinsicContentSize: CGSize {
        if let intrinsicContentSize = titleLabel?.intrinsicContentSize {
            return CGSize(width: intrinsicContentSize.width, height: intrinsicContentSize.height + contentEdgeInsets.top + contentEdgeInsets.bottom)
        }

        return .zero
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        titleLabel?.preferredMaxLayoutWidth = titleLabel?.frame.size.width ?? 0
        super.layoutSubviews()
    }

    // MARK: - View setup

    private func setup() {
        setTitleColor(.textSubtle, for: .normal)
        titleLabel?.lineBreakMode = .byWordWrapping
        titleLabel?.numberOfLines = 0
        titleLabel?.font = WPStyleGuide.fontForTextStyle(.subheadline)
        titleLabel?.textColor = .textSubtle
        contentHorizontalAlignment = .leading
        contentVerticalAlignment = .top
        addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
    }

    @objc private func buttonTapped() {
        onTap?()
    }

    private func setTitle(title: String, hint: String) {
        let externalAttachment = NSTextAttachment(image: UIImage.gridicon(.external, size: Constants.iconSize).withTintColor(.primary))
        externalAttachment.bounds = Constants.iconBounds

        let attachmentString = NSAttributedString(attachment: externalAttachment)

        let titleString = NSMutableAttributedString(string: "\(title) \u{FEFF}")
        if let subStringRange = title.nsRange(of: hint) {
            titleString.addAttributes([
                .foregroundColor: UIColor.primary,
                .font: WPStyleGuide.fontForTextStyle(.subheadline).bold()
            ], range: subStringRange)
        }

        titleString.append(attachmentString)

        setAttributedTitle(titleString, for: .normal)
    }

    private enum Constants {
        static let iconSize = CGSize(width: 16, height: 16)
        static let iconBounds = CGRect(x: 0, y: -2, width: 16, height: 16)
    }

}
