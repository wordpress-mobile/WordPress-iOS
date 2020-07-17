import Foundation
import WordPressShared

class ReaderInterestsStyleGuide {
    // MARK: - View Styles
    public class func applyTitleLabelStyles(label: UILabel) {
        label.font = WPStyleGuide.serifFontForTextStyle(.largeTitle, fontWeight: .medium)
        label.textColor = .text
    }

    public class func applySubtitleLabelStyles(label: UILabel) {
        label.font = WPStyleGuide.fontForTextStyle(.body)
        label.textColor = .text
    }

    // MARK: - Collection View Cell Styles
    public class var cellLabelTitleFont: UIFont {
        return WPStyleGuide.fontForTextStyle(.body)
    }

    public class func applyCellLabelStyle(label: UILabel, isSelected: Bool) {
        label.font = WPStyleGuide.fontForTextStyle(.body)
        label.textColor = isSelected ? .white : .text
        label.backgroundColor = isSelected ? .muriel(color: .primary, .shade40) : .quaternaryBackground
    }

    // MARK: - Next Button
    public class var buttonContainerViewBackgroundColor: UIColor {
        if #available(iOS 13, *) {
            return .tertiarySystemBackground
        }

        return .white
    }

    public class func applyNextButtonStyle(button: FancyButton) {
        let disabledBackgroundColor: UIColor

        if #available(iOS 13.0, *) {
            // System Gray 4 on Dark mode is the same color as tertiarySystemBackground
            disabledBackgroundColor = UIColor(light: .systemGray4, dark: .systemGray3)
        } else {
            disabledBackgroundColor = .lightGray
        }

        button.disabledTitleColor = .textTertiary
        button.disabledBorderColor = disabledBackgroundColor
        button.disabledBackgroundColor = disabledBackgroundColor
    }
}
