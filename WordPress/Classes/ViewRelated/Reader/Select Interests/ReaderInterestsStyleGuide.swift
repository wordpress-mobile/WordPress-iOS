import Foundation
import WordPressShared

class ReaderInterestsStyleGuide {

    struct Metrics {
        let interestsLabelMargin: CGFloat
        let cellCornerRadius: CGFloat
        let cellSpacing: CGFloat
        let cellHeight: CGFloat
        let maxCellWidthMultiplier: CGFloat
        let borderWidth: CGFloat
        let borderColor: UIColor

        static let latest = Metrics(
            interestsLabelMargin: 16.0,
            cellCornerRadius: 5.0,
            cellSpacing: 8.0,
            cellHeight: 34.0,
            maxCellWidthMultiplier: 0.8,
            borderWidth: 1.0,
            borderColor: .separator
        )
    }

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

    // MARK: - Compact Collection View Cell Styles
    public class var compactCellLabelTitleFont: UIFont {
        return WPStyleGuide.fontForTextStyle(.footnote)
    }

    public class func applyCompactCellLabelStyle(label: UILabel) {
        label.font = Self.compactCellLabelTitleFont
        label.textColor = .text
        label.backgroundColor = .clear
    }

    // MARK: - Next Button
    public static let buttonContainerViewBackgroundColor: UIColor = .tertiarySystemBackground

    public class func applyNextButtonStyle(button: FancyButton) {
        let disabledBackgroundColor: UIColor
        let titleColor: UIColor

        disabledBackgroundColor = UIColor(light: .systemGray4, dark: .systemGray3)
        titleColor = .textTertiary

        button.disabledTitleColor = titleColor
        button.disabledBorderColor = disabledBackgroundColor
        button.disabledBackgroundColor = disabledBackgroundColor
    }

    // MARK: - Loading
    public class func applyLoadingLabelStyles(label: UILabel) {
        label.font = WPStyleGuide.fontForTextStyle(.body)
        label.textColor = .textSubtle
    }

    public class func applyActivityIndicatorStyles(indicator: UIActivityIndicatorView) {
        indicator.color = UIColor(light: .black, dark: .white)
    }
}

class ReaderSuggestedTopicsStyleGuide {
    public static var topicFont: UIFont = WPStyleGuide.fontForTextStyle(.footnote)
}
