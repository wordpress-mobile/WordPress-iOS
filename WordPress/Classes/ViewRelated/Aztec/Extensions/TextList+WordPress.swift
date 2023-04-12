import Foundation
import Aztec


// MARK: - TextList.Style
//
extension TextList.Style {

    var formattingIdentifier: FormattingIdentifier {
        switch self {
        case .ordered: return FormattingIdentifier.orderedlist
        case .unordered: return FormattingIdentifier.unorderedlist
        @unknown default: fatalError()
        }
    }

    var description: String {
        switch self {
        case .ordered: return "Ordered List"
        case .unordered: return "Unordered List"
        @unknown default: fatalError()
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .ordered: return AppLocalizedString("Toggles the ordered list style", comment: "Accessibility Identifier for the Aztec Ordered List Style.")
        case .unordered: return AppLocalizedString("Toggles the unordered list style", comment: "Accessibility Identifier for the Aztec Unordered List Style")
        @unknown default:
            fatalError()
        }
    }

    var iconImage: UIImage? {
        return formattingIdentifier.iconImage
    }
}
