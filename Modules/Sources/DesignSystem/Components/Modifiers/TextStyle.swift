public enum TextStyle {
    case heading1
    case heading2
    case heading3
    case heading4
    case bodySmall(Weight)
    case bodyMedium(Weight)
    case bodyLarge(Weight)
    case footnote
    case caption

    public enum Weight {
        case regular
        case emphasized
    }
}
