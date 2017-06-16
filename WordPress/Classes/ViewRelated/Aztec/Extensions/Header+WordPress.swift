import Foundation
import Aztec


// MARK: - Header and List presentation extensions
//
extension Header.HeaderType {
    var formattingIdentifier: FormattingIdentifier {
        switch self {
        case .none: return FormattingIdentifier.p
        case .h1:   return FormattingIdentifier.header1
        case .h2:   return FormattingIdentifier.header2
        case .h3:   return FormattingIdentifier.header3
        case .h4:   return FormattingIdentifier.header4
        case .h5:   return FormattingIdentifier.header5
        case .h6:   return FormattingIdentifier.header6
        }
    }

    var description: String {
        switch self {
        case .none: return NSLocalizedString("Default", comment: "Description of the default paragraph formatting style in the editor.")
        case .h1: return NSLocalizedString("Heading 1", comment: "H1 Aztec Style")
        case .h2: return NSLocalizedString("Heading 2", comment: "H2 Aztec Style")
        case .h3: return NSLocalizedString("Heading 3", comment: "H3 Aztec Style")
        case .h4: return NSLocalizedString("Heading 4", comment: "H4 Aztec Style")
        case .h5: return NSLocalizedString("Heading 5", comment: "H5 Aztec Style")
        case .h6: return NSLocalizedString("Heading 6", comment: "H6 Aztec Style")
        }
    }

    var iconImage: UIImage? {
        return formattingIdentifier.iconImage
    }
}
