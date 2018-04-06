import Foundation


public extension UIImageView {

    /// Downloads a resized Blavatar, meant to perfectly fit the UIImageView's Dimensions
    ///
    /// - Parameter url: The URL of the target blavatar
    ///
    public func downloadBlavatar(from url: URL) {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        components?.query = String(format: Downloader.blavatarResizeFormat, blavatarSize)

        guard let updatedURL = components?.url else {
            assertionFailure()
            return
        }

        let size = CGSize(width: blavatarSizeInPoints, height: blavatarSizeInPoints)
        downloadResizedImage(from: updatedURL, pointSize: size)
    }


    /// Returns the desired Blavatar Side-Size, in pixels
    ///
    private var blavatarSize: Int {
        return blavatarSizeInPoints * Int(mainScreenScale)
    }


    /// Returns the desired Blavatar Side-Size, in points
    ///
    private var blavatarSizeInPoints: Int {
        var size = Downloader.defaultImageSize

        if !bounds.size.equalTo(.zero) {
            size = max(bounds.width, bounds.height)
        }

        return Int(size)
    }


    /// Returns the Main Screen Scale
    ///
    private var mainScreenScale: CGFloat {
        return UIScreen.main.scale
    }


    /// Private helper structure
    ///
    private struct Downloader {
        /// Default Blavatar Image Size
        ///
        static let defaultImageSize = CGFloat(40)

        /// Blavatar Resize Query FormatString
        ///
        static let blavatarResizeFormat = "d=404&s=%d"
    }
}
