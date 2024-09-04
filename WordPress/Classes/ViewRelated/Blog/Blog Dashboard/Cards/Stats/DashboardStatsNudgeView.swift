import UIKit

final class DashboardStatsNudgeView: UIView {

    var onTap: (() -> Void)? {
        didSet {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(buttonTapped))
            addGestureRecognizer(tapGesture)
        }
    }

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = WPStyleGuide.fontForTextStyle(.subheadline)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        return label
    }()

    // MARK: - Init

    convenience init(title: String, hint: String?, insets: UIEdgeInsets = Constants.margins) {
        self.init(frame: .zero)

        setup(insets: insets)
        setTitle(title: title, hint: hint)
    }

    // MARK: - View setup

    private func setup(insets: UIEdgeInsets) {
        addSubview(titleLabel)
        pinSubviewToAllEdges(titleLabel, insets: insets)

        prepareForVoiceOver()
    }

    @objc private func buttonTapped() {
        onTap?()
    }

    private func setTitle(title: String, hint: String?) {
        let externalAttachment = NSTextAttachment(image: UIImage.gridicon(.external, size: Constants.iconSize).withTintColor(AppColor.primary))
        externalAttachment.bounds = Constants.iconBounds

        let attachmentString = NSAttributedString(attachment: externalAttachment)

        let titleString = NSMutableAttributedString(string: "\(title) \u{FEFF}")
        if let hint = hint,
           let subStringRange = title.nsRange(of: hint) {
            titleString.addAttributes([
                .foregroundColor: AppColor.primary,
                .font: WPStyleGuide.fontForTextStyle(.subheadline).bold()
            ], range: subStringRange)
        }

        titleString.append(attachmentString)

        titleLabel.attributedText = titleString
    }

    private enum Constants {
        static let iconSize = CGSize(width: 16, height: 16)
        static let iconBounds = CGRect(x: 0, y: -2, width: 16, height: 16)
        static let margins = UIEdgeInsets(top: 0, left: 16, bottom: 8, right: 16)
    }

}

extension DashboardStatsNudgeView: Accessible {

    func prepareForVoiceOver() {
        isAccessibilityElement = false
        titleLabel.isAccessibilityElement = true
        titleLabel.accessibilityTraits = .button
    }
}
