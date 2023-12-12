import Foundation

public enum Length {
    public enum Padding {
        public static let half: CGFloat = 4
        public static let single: CGFloat = 8
        public static let split: CGFloat = 12
        public static let double: CGFloat = 16
        public static let medium: CGFloat = 24
        public static let large: CGFloat = 32
        public static let max: CGFloat = 48
    }

    public enum Hitbox {
        public static let minTappableLength: CGFloat = 44
    }

    public enum Radius {
        public static let small: CGFloat = 5
        public static let medium: CGFloat = 10
        public static let large: CGFloat = 15
        public static let max: CGFloat = 20
    }

    public enum Border {
        public static let thin: CGFloat = 0.5
    }
}
