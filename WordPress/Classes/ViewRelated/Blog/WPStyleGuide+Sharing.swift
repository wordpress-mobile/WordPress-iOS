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
        case "print" :
            return .gridicon(.print)
        case "email" :
            return .gridicon(.mail)
        case "google-plus-1" :
            iconName = "social-google-plus"
        case "press-this" :
            iconName = "social-wordpress"
        default :
            iconName = "social-\(name)"
        }

        var image = UIImage(named: iconName)
        if image == nil {
            image = UIImage(named: "social-default")
        }
        return image!.withRenderingMode(.alwaysTemplate)
    }


    /// Get's the tint color to use for the specified service when it is connected.
    ///
    /// - Parameters:
    ///     - service: The name of the service.
    ///
    /// - Returns: The tint color for the service, or the default color.
    ///
    @objc public class func tintColorForConnectedService(_ service: String) -> UIColor {
        guard let name = SharingServiceNames(rawValue: service) else {
            return .primary
        }

        switch name {
        case .Facebook:
            return UIColor(fromRGBAColorWithRed: 59.0, green: 89.0, blue: 152.0, alpha: 1)
        case .Twitter:
            return UIColor(fromRGBAColorWithRed: 85, green: 172, blue: 238, alpha: 1)
        case .Google:
            return UIColor(fromRGBAColorWithRed: 220, green: 78, blue: 65, alpha: 1)
        case .LinkedIn:
            return UIColor(fromRGBAColorWithRed: 0, green: 119, blue: 181, alpha: 1)
        case .Tumblr:
            return UIColor(fromRGBAColorWithRed: 53, green: 70, blue: 92, alpha: 1)
        case .Path:
            return UIColor(fromRGBAColorWithRed: 238, green: 52, blue: 35, alpha: 1)
        }
    }

    enum SharingServiceNames: String {
        case Facebook = "facebook"
        case Twitter = "twitter"
        case Google = "google_plus"
        case LinkedIn = "linkedin"
        case Tumblr = "tumblr"
        case Path = "path"
    }
}
