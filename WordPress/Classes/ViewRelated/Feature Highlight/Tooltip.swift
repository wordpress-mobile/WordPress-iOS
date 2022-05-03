import UIKit

final class Tooltip: UIView {
    private enum Constants {
        static let leadingIconUnicode = "✨"
    }

    var title: String? {
        didSet {
            guard let title = title else {
                titleLabel.text = nil
                return
            }

            Self.updateTitleLabel(
                titleLabel,
                with: title,
                shouldPrefixLeadingIcon: shouldPrefixLeadingIcon
            )
        }
    }

    var shouldPrefixLeadingIcon: Bool = true {
        didSet {
            guard let title = title else { return }

            Self.updateTitleLabel(
                titleLabel,
                with: title,
                shouldPrefixLeadingIcon: shouldPrefixLeadingIcon
            )
        }
    }

    private let titleLabel: UILabel = {
        $0.font = WPStyleGuide.fontForTextStyle(.body)
        return $0
    }(UILabel())

    private let descriptionLabel: UILabel = {
        $0.font = WPStyleGuide.fontForTextStyle(.body)
        return $0
    }(UILabel())

    private let primaryButton: UIButton = {
        $0.titleLabel?.font = WPStyleGuide.fontForTextStyle(.subheadline)
        return $0
    }(UIButton())

    private let secondaryButton: UIButton = {
        return $0
    }(UIButton())

    private let contentStackView: UIStackView = {
        return $0
    }(UIStackView())

    private let buttonsStackView: UIStackView = {
        return $0
    }(UIStackView())

    private static func updateTitleLabel(
        _ titleLabel: UILabel,
        with text: String,
        shouldPrefixLeadingIcon: Bool) {

        if shouldPrefixLeadingIcon {
            titleLabel.text = Constants.leadingIconUnicode + " " + text
        } else {
            titleLabel.text = text
        }
    }
}
