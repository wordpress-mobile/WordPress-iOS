// MARK: - Internationalization helper

extension UIControl {
    public enum NaturalContentHorizontalAlignment {
        case leading
        case trailing
    }

    /// iOS 10 compatible leading/trailing contentHorizontalAlignment. Prefer this to set content alignment to respect Right-to-Left language layouts.
    ///
    public var naturalContentHorizontalAlignment: NaturalContentHorizontalAlignment? {
        get {
            switch contentHorizontalAlignment {
            case .left, .leading:
                return .leading
            case .right, .trailing:
                return .trailing
            default:
                return nil
            }
        }

        set(alignment) {
            if #available(iOS 11.0, *) {
                contentHorizontalAlignment = (alignment == .leading) ? .leading : .trailing
            } else {
                if userInterfaceLayoutDirection() == .leftToRight {
                    contentHorizontalAlignment = (alignment == .leading) ? .left : .right
                } else {
                    contentHorizontalAlignment = (alignment == .leading) ? .right : .left
                }
            }
        }
    }
}
