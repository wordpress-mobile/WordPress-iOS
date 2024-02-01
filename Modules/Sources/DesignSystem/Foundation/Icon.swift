import UIKit
import SwiftUI

/// `Icon` provides a namespace for icon identifiers.
///
/// The naming convention follows the SF Symbols guidelines, enhancing consistency and readability.
/// Each icon name is a dot-syntax representation of the icon's hierarchy and style.
///
/// For example, `ellipsis.vertical` represents a vertical ellipsis icon.
public enum Icon: String, CaseIterable {
    case ellipsisVertical = "ellipsis.vertical"
}

// MARK: - Load Image

public extension UIImage {
    enum DS {
        public static func icon(named name: Icon, with configuration: UIImage.Configuration? = nil) -> UIImage? {
            return UIImage(named: name.rawValue, in: .module, with: configuration)
        }
    }
}

public extension Image {
    enum DS {
        public static func icon(named name: Icon) -> Image {
            return Image(name.rawValue, bundle: .module)
        }
    }
}
