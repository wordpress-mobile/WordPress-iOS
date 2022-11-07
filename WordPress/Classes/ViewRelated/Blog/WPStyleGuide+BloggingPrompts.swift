/// This class groups styles used by blogging prompts
///
extension WPStyleGuide {
    public struct BloggingPrompts {
        static let promptContentFont = WPStyleGuide.serifFontForTextStyle(.headline, fontWeight: .semibold)
        static let answerInfoLabelFont = WPStyleGuide.fontForTextStyle(.caption1)
        static let answerInfoLabelColor = UIColor.textSubtle
        static let buttonTitleFont = WPStyleGuide.fontForTextStyle(.subheadline)
        static let buttonTitleColor = UIColor.primary
        static let answeredLabelColor = UIColor.muriel(name: .green, .shade50)
    }
}
