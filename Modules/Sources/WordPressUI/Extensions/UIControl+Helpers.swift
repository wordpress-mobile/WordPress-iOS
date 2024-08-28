import UIKit

// MARK: - Internationalization helper

extension UIControl {
    public enum NaturalContentHorizontalAlignment {
        case leading
        case trailing
        case center
    }

    /// iOS 10 compatible leading/trailing contentHorizontalAlignment. Prefer this to set content alignment to respect Right-to-Left language layouts.
    ///
    public var naturalContentHorizontalAlignment: NaturalContentHorizontalAlignment {
        get {
            switch contentHorizontalAlignment {
            case .left, .leading:
                return .leading
            case .right, .trailing:
                return .trailing
            case .center:
                fallthrough
            default:
                return .center
            }
        }

        set(alignment) {
            switch alignment {
            case .leading:
                contentHorizontalAlignment = .leading
            case .trailing:
                contentHorizontalAlignment = .trailing
            case .center:
                fallthrough
            default:
                contentHorizontalAlignment = .center
            }
        }
    }
}
