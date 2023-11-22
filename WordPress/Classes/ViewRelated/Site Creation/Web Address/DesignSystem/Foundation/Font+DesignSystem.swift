import SwiftUI

public extension Font {
    enum DS {
        public static let heading1 = Font.largeTitle
        public static let heading2 = Font.title
        public static let heading3 = Font.title2
        public static let heading4 = Font.title3

        public enum Body {
            public static let small = Font.body
            public static let medium = Font.callout
            public static let large = Font.subheadline

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
