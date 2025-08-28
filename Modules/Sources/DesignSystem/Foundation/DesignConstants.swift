import Foundation

public enum DesignConstants {
    public enum Radius {
        /// Radius applicable for large components like cards that take full
        /// screen width
        case large
    }

    public static func radius(_ radius: Radius) -> CGFloat {
        if #available(iOS 26, *) {
            return 26
        } else {
            return 10
        }
    }
}
