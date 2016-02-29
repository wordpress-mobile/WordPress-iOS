import Foundation
import WordPressShared

/// A WPStyleGuide extension with styles and methods specific to the
/// Sharing feature.
///
extension WPStyleGuide
{
    /// Create an UIImageView showing the notice gridicon.
    ///
    /// - Returns: A UIImageView
    ///
    public class func sharingCellWarningAccessoryImageView() -> UIImageView {

        let imageSize = 20.0
        let horizontalPadding = 8.0;
        let imageView = UIImageView(frame:CGRect(x: 0, y: 0, width: imageSize + horizontalPadding, height: imageSize))

        let noticeImage = UIImage(named: "gridicons-notice")
        imageView.image = noticeImage?.imageWithRenderingMode(.AlwaysTemplate)
        imageView.tintColor = jazzyOrange()
        imageView.contentMode = .Right
        return imageView
    }


    /// Creates an icon for the specified service, or a the default social icon.
    ///
    /// - Parameters:
    ///     - service: The name of the service.
    ///
    /// - Returns: A template UIImage that can be tinted by a UIImageView's tintColor property.
    ///
    public class func iconForService(service: NSString) -> UIImage {
        let name = service.lowercaseString.stringByReplacingOccurrencesOfString("_", withString: "-")
        var iconName: String

        // Handle special cases
        switch name {
        case "print" :
            iconName = "gridicons-print"
        case "email" :
            iconName = "gridicons-mail"
        case "google-plus-one" :
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
        return image!.imageWithRenderingMode(.AlwaysTemplate)
    }


    /// Get's the tint color to use for the specified service when it is connected.
    ///
    /// - Parameters:
    ///     - service: The name of the service.
    ///
    /// - Returns: The tint color for the service, or the default color.
    ///
    public class func tintColorForConnectedService(service: String) -> UIColor {
        guard let name = SharingServiceNames(rawValue: service) else {
            return WPStyleGuide.wordPressBlue()
        }

        switch name {
        case .Facebook:
            return UIColor(fromRGBAColorWithRed: 59.0, green: 89.0, blue: 152.0, alpha:1)
        case .Twitter:
            return UIColor(fromRGBAColorWithRed: 85, green: 172, blue: 238, alpha:1)
        case .Google:
            return UIColor(fromRGBAColorWithRed: 220, green: 78, blue: 65, alpha:1)
        case .LinkedIn:
            return UIColor(fromRGBAColorWithRed: 0, green: 119, blue: 181, alpha:1)
        case .Tumblr:
            return UIColor(fromRGBAColorWithRed: 53, green: 70, blue: 92, alpha:1)
        case .Path:
            return UIColor(fromRGBAColorWithRed: 238, green: 52, blue: 35, alpha:1)
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
