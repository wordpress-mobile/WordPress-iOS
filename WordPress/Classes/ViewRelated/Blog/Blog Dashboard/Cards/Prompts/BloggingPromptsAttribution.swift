enum BloggingPromptsAttribution: String {
    case dayone

    var attributedText: NSAttributedString {
        let baseText = String(format: Strings.fromTextFormat, source)
        let attributedText = NSMutableAttributedString(string: baseText, attributes: Constants.baseAttributes)
        guard let range = baseText.range(of: source) else {
            return attributedText
        }
        attributedText.addAttributes(Constants.sourceAttributes, range: NSRange(range, in: baseText))

        return attributedText
    }

    var source: String {
        switch self {
        case .dayone: return Strings.dayOne
        }
    }

    var iconImage: UIImage? {
        switch self {
        case .dayone: return Constants.dayOneIcon
        }
    }

    private struct Strings {
        static let fromTextFormat = NSLocalizedString("From %1$@", comment: "Format for blogging prompts attribution. %1$@ is the attribution source.")
        static let dayOne = "Day One"
    }

    private struct Constants {
        static let baseAttributes: [NSAttributedString.Key: Any] = [
            .font: WPStyleGuide.fontForTextStyle(.caption1),
            .foregroundColor: UIColor.secondaryLabel,
        ]
        static let sourceAttributes: [NSAttributedString.Key: Any] = [
            .font: WPStyleGuide.fontForTextStyle(.caption1, fontWeight: .medium),
            .foregroundColor: UIColor.text,
        ]
        static let iconSize = CGSize(width: 18, height: 18)
        static let dayOneIcon = UIImage(named: "logo-dayone")?.resizedImage(Constants.iconSize, interpolationQuality: .default)
    }
}
