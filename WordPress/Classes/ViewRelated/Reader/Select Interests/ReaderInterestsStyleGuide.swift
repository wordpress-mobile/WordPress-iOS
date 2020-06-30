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
        return .tertiaryBackground
    }

    public class func applyNextButtonStyle(button: FancyButton) {
        // TODO
    }
}
