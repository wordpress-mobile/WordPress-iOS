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

    // MARK: - Compact Collection View Cell Styles
    public class var compactCellLabelTitleFont: UIFont {
        return WPStyleGuide.fontForTextStyle(.footnote)
    }

    public class func applyCompactCellLabelStyle(label: UILabel) {
        label.font = Self.compactCellLabelTitleFont
        label.textColor = .text
        label.backgroundColor = .quaternaryBackground
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
    struct TopicStyle {
        let textColor: UIColor
        let backgroundColor: UIColor
        let borderColor: UIColor
    }

    /// The array of colors from the designs
    /// Note: I am explictly using the MurielColor names instead of using the semantic ones
    ///       since these are explicit and not semantic colors.
    static let colors: [TopicStyle] = [
        // Green
        .init(textColor: .muriel(color: MurielColor(name: .green), .shade50),
              backgroundColor: .muriel(color: MurielColor(name: .green), .shade0),
              borderColor: .muriel(color: MurielColor(name: .green), .shade5)),

        // Blue
        .init(textColor: .muriel(color: MurielColor(name: .blue), .shade50),
              backgroundColor: .muriel(color: MurielColor(name: .blue), .shade0),
              borderColor: .muriel(color: MurielColor(name: .blue), .shade5)),

        // Yellow
        .init(textColor: .muriel(color: MurielColor(name: .yellow), .shade50),
              backgroundColor: .muriel(color: MurielColor(name: .yellow), .shade0),
              borderColor: .muriel(color: MurielColor(name: .yellow), .shade5)),

        // Orange
        .init(textColor: .muriel(color: MurielColor(name: .orange), .shade50),
              backgroundColor: .muriel(color: MurielColor(name: .orange), .shade0),
              borderColor: .muriel(color: MurielColor(name: .orange), .shade5)),
    ]

    private class func topicStyle(for index: Int) -> TopicStyle {
        let colorCount = Self.colors.count

        // Safety feature if for some reason the count of returned topics ever increases past 4 we will
        // loop through the list colors again. 
        return Self.colors[index % colorCount]
    }

    public static var topicFont: UIFont = WPStyleGuide.fontForTextStyle(.body)

    public class func applySuggestedTopicStyle(label: UILabel, with index: Int) {
        let style = Self.topicStyle(for: index)

        label.font = WPStyleGuide.fontForTextStyle(.body)
        label.textColor = style.textColor

        label.layer.borderColor = style.borderColor.cgColor
        label.layer.borderWidth = .hairlineBorderWidth
        label.layer.backgroundColor = style.backgroundColor.cgColor
    }
}
