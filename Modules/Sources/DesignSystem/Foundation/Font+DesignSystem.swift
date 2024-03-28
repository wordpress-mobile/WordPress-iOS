import SwiftUI

public extension Font {
    enum DS {
        public static let heading1 = Font.largeTitle.weight(.semibold)
        public static let heading2 = Font.title.weight(.semibold)
        public static let heading3 = Font.title2.weight(.semibold)
        public static let heading4 = Font.title3.weight(.semibold)

        public enum Body {
            public static let small = Font.subheadline
            public static let medium = Font.callout
            public static let large = Font.body

            public enum Emphasized {
                public static let small = Body.small.weight(.semibold)
                public static let medium = Body.medium.weight(.semibold)
                public static let large = Body.large.weight(.semibold)
            }
        }

        public static let footnote = Font.footnote
        public static let caption = Font.caption
    }
}

public extension Font.DS {
    static func font(_ style: DesignSystem.TextStyle) -> Font {
        switch style {
        case .heading1:
            return Font.DS.heading1

        case .heading2:
            return Font.DS.heading2

        case .heading3:
            return Font.DS.heading3

        case .heading4:
            return Font.DS.heading4

        case .bodySmall(let weight):
            switch weight {
            case .regular:
                return Font.DS.Body.small
            case .emphasized:
                return Font.DS.Body.Emphasized.small
            }

        case .bodyMedium(let weight):
            switch weight {
            case .regular:
                return Font.DS.Body.medium
            case .emphasized:
                return Font.DS.Body.Emphasized.medium
            }

        case .bodyLarge(let weight):
            switch weight {
            case .regular:
                return Font.DS.Body.large
            case .emphasized:
                return Font.DS.Body.Emphasized.large
            }

        case .footnote:
            return Font.DS.footnote

        case .caption:
            return Font.DS.caption
        }
    }
}
