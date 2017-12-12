import Foundation


/// UIImageView Helper Methods that allow us to download a Gravatar, given the User's Email
///
extension UIImageView {

    /// Default Settings
    ///
    struct BlavatarDefaults {

        /// Default Blavatar's Image Size, in points.
        ///
        static let imageSize = 40

        /// Default Blavatar's Image Size, in pixels.
        ///
        static var imageSizeInPixels: Int {
            return imageSize * Int(UIScreen.main.scale)
        }
    }


    /// Downloads the Blavatar hosted at the specified siteIcon Path.
    ///
    /// - Parameter path: Site Icon's Path.
    /// - TODO: This is a convenience method. Nuke me once we're all swifted.
    ///
    @objc
    func downloadBlavatar(at path: String) {
        downloadBlavatar(at: path, placeholderImage: .blavatarPlaceholderImage)
    }


    /// Downloads the Blavatar hosted at the specified siteIcon Path.
    ///
    /// - Parameters:
    ///     - path: Site Icon's Path.
    ///     - placeholderImage: the image to be used as a placeholder
    ///
    @objc
    func downloadBlavatar(at path: String, placeholderImage: UIImage?) {
        guard let url = optimizedURL(for: path) else {
            return
        }

        setImageWith(url, placeholderImage: placeholderImage)
    }


    /// Downloads a Blavatar Image associated to the specified Blog.
    ///
    /// Parameters:
    ///  - blog: reference to the source blog
    ///  - placeholderImage: the placeholder
    ///
    @objc
    func downloadBlavatar(for blog: Blog, placeholderImage: UIImage? = .blavatarPlaceholderImage) {
        guard let siteIconPath = blog.icon else {
            return
        }

        if blog.isHostedAtWPcom && blog.isPrivate() {
            downloadPrivateBlavatar(at: siteIconPath, placeholderImage: placeholderImage)
        } else {
            downloadBlavatar(at: siteIconPath, placeholderImage: placeholderImage)
        }
    }
}


// MARK: - Private Site Blavatar Support
//
private extension UIImageView {

    /// Downloads the Private Site Icon, hosted at the indicated path.
    ///
    /// - Parameters:
    ///     - path: the icon's path
    ///     - placeholderImage: the placeholder
    ///
    func downloadPrivateBlavatar(at path: String, placeholderImage: UIImage?) {
        guard let iconURL = optimizedURL(for: path),
            let request = PrivateSiteURLProtocol.requestForPrivateSite(from: iconURL)
        else {
            return
        }

        setImageWith(request, placeholderImage: placeholderImage, success: nil, failure: nil)
    }
}


// MARK: - Private Methods
//
private extension UIImageView {

    /// Returns the Size Optimized URL for a given Path.
    ///
    func optimizedURL(for path: String) -> URL? {
        if isPhotonURL(path) || isDotcomURL(path) {
            return optimizedDotcomURL(from: path)
        }

        if isBlavatarURL(path) {
            return optimizedBlavatarURL(from: path)
        }

        return optimizedPhotonURL(from: path)
    }


    // MARK: - Private Helpers

    /// Returns the download URL for a square icon with a size of sizeForBlavatarDownload
    ///
    /// - Parameter path: the icon's path
    ///
    private func optimizedDotcomURL(from siteIconPath: String) -> URL? {
        let size = BlavatarDefaults.imageSizeInPixels
        return URLComponents.parseURL(path: siteIconPath, query: String(format: "w=%d&h=%d", size, size))
    }


    /// Returns the icon URL corresponding to the provided path
    ///
    /// - Parameter path: source icon path
    ///
    private func optimizedBlavatarURL(from siteIconPath: String) -> URL? {
        let size = BlavatarDefaults.imageSizeInPixels
        return URLComponents.parseURL(path: siteIconPath, query: String(format: "d=404&s=%d", size))
    }


    /// Returs the photon URL for the provided path
    ///
    /// - Parameter urlString: source URL
    ///
    private func optimizedPhotonURL(from urlString: String) -> URL? {
        guard let url = URL(string: urlString) else {
            return nil
        }

        let size = CGSize(width: BlavatarDefaults.imageSize, height: BlavatarDefaults.imageSize)
        return PhotonImageURLHelper.photonURL(with: size, forImageURL: url)
    }


    /// Indicates if the received URL is hosted at WordPress.com
    ///
    private func isDotcomURL(_ path: String) -> Bool {
        return path.contains(".files.wordpress.com")
    }


    /// Indicates if the received URL is hosted at Gravatar.com
    ///
    private func isBlavatarURL(_ path: String) -> Bool {
        return path.contains("gravatar.com/blavatar")
    }


    /// Indicates if the received URL is a Photon Endpoint
    /// Possible matches are "i0.wp.com", "i1.wp.com" & "i2.wp.com" -> https://developer.wordpress.com/docs/photon/
    ///
    private func isPhotonURL(_ path: String) -> Bool {
        return path.contains(".wp.com")
    }
}

