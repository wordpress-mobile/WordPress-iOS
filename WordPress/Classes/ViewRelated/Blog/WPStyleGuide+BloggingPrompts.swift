/// This class groups styles used by blogging prompts
///
extension WPStyleGuide {
    public struct BloggingPrompts {
        static let promptContentFont = AppStyleGuide.prominentFont(textStyle: .headline, weight: .semibold)
        static let answerInfoButtonFont = WPStyleGuide.fontForTextStyle(.caption1)
        static let answerInfoButtonColor = UIColor.textSubtle
        static let buttonTitleFont = WPStyleGuide.fontForTextStyle(.subheadline)
        static let buttonTitleColor = UIColor.primary
        static let answeredLabelColor = UIColor.muriel(name: .green, .shade50)
    }
}
