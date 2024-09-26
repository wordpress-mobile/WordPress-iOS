import Foundation
import Gridicons
import WordPressShared

/// A WPStyleGuide extension with styles and methods specific to the
/// Sharing feature.
///
extension WPStyleGuide {
    /// Create an UIImageView showing the notice gridicon.
    ///
    /// - Returns: A UIImageView
    ///
    @objc public class func sharingCellWarningAccessoryImageView() -> UIImageView {
        let imageSize = 20.0
        let horizontalPadding = 8.0
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: imageSize + horizontalPadding, height: imageSize))

        imageView.image = UIImage(named: "sharing-notice")
        imageView.tintColor = jazzyOrange()
        imageView.contentMode = .right
        return imageView
    }

    /// Create an UIImageView showing the notice gridicon.
    ///
    /// - Returns: A UIImageView
    ///
    @objc public class func sharingCellErrorAccessoryImageView() -> UIImageView {
        let imageSize = 20.0
        let horizontalPadding = 8.0
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: imageSize + horizontalPadding, height: imageSize))

        imageView.image = UIImage(named: "sharing-notice")
        imageView.tintColor = .systemRed
        imageView.contentMode = .right
        return imageView
    }

    /// Creates an icon for the specified service, or a the default social icon.
    ///
    /// - Parameters:
    ///     - service: The name of the service.
    ///
    /// - Returns: A template UIImage that can be tinted by a UIImageView's tintColor property.
    ///
    @objc public class func iconForService(_ service: NSString) -> UIImage {
        let name = service.lowercased.replacingOccurrences(of: "_", with: "-")
        var iconName: String

        // Handle special cases
        switch name {
        case "print":
            return .gridicon(.print)
        case "email":
            return .gridicon(.mail)
        case "google-plus-1":
            iconName = "social-google-plus"
        case "press-this":
            iconName = "social-wordpress"
        default:
            iconName = "social-\(name)"
        }

        var image = UIImage(named: iconName)
        if image == nil {
            image = UIImage(named: "social-default")
        }
        return image!.withRenderingMode(.alwaysTemplate)
    }

    @objc public class func socialIcon(for service: NSString) -> UIImage {
        UIImage(named: "icon-\(service)") ?? iconForService(service)
    }
}
