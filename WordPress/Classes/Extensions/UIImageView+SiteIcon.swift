import Foundation


/// UIImageView Helper Methods that allow us to download a SiteIcon, given a website's "Icon Path"
///
extension UIImageView {

    /// Default Settings
    ///
    struct SiteIconDefaults {

        /// Default SiteIcon's Image Size, in points.
        ///
        static let imageSize = 40

        /// Default SiteIcon's Image Size, in pixels.
        ///
        static var imageSizeInPixels: Int {
            return imageSize * Int(UIScreen.main.scale)
        }
    }


    /// Downloads the SiteIcon Image, hosted at the specified path. This method will attempt to optimize the URL, so that
    /// the download Image Size matches `SiteIconDefaults.imageSize`.
    ///
    /// TODO: This is a convenience method. Nuke me once we're all swifted.
    ///
    /// - Parameter path: SiteIcon's url (string encoded) to be downloaded.
    ///
    @objc
    func downloadSiteIcon(at path: String) {
        downloadSiteIcon(at: path, placeholderImage: .siteIconPlaceholderImage)
    }


    /// Downloads the SiteIcon Image, hosted at the specified path. This method will attempt to optimize the URL, so that
    /// the download Image Size matches `SiteIconDefaults.imageSize`.
    ///
    /// - Parameters:
    ///     - path: SiteIcon's url (string encoded) to be downloaded.
    ///     - placeholderImage: Yes. It's the "place holder image", Sherlock.
    ///
    @objc
    func downloadSiteIcon(at path: String, placeholderImage: UIImage?) {
        guard let siteIconURL = optimizedURL(for: path) else {
            image = placeholderImage
            return
        }

        setImageWith(siteIconURL, placeholderImage: placeholderImage)
    }


    /// Downloads the SiteIcon Image, associated to a given Blog. This method will attempt to optimize the URL, so that
    /// the download Image Size matches `SiteIconDefaults.imageSize`.
    ///
    /// - Parameters:
    ///     - blog: reference to the source blog
    ///     - placeholderImage: Yes. It's the "place holder image".
    ///
    @objc
    func downloadSiteIcon(for blog: Blog, placeholderImage: UIImage? = .siteIconPlaceholderImage) {
        guard let siteIconPath = blog.icon, let siteIconURL = optimizedURL(for: siteIconPath) else {
            image = placeholderImage
            return
        }

        if !blog.isPrivate() {
            setImageWith(siteIconURL, placeholderImage: placeholderImage)
            return
        }

        let request = PrivateSiteURLProtocol.requestForPrivateSite(from: siteIconURL)
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

    /// Returns the download URL for a square icon with a size of `SiteIconDefaults.imageSizeInPixels`
    ///
    /// - Parameter path: SiteIcon URL (string encoded).
    ///
    private func optimizedDotcomURL(from path: String) -> URL? {
        let size = SiteIconDefaults.imageSizeInPixels
        let query = String(format: "w=%d&h=%d", size, size)

        return URLComponents.parseURL(path: path, query: query)
    }


    /// Returns the icon URL corresponding to the provided path
    ///
    /// - Parameter path: Blavatar URL (string encoded).
    ///
    private func optimizedBlavatarURL(from path: String) -> URL? {
        let size = SiteIconDefaults.imageSizeInPixels
        let query = String(format: "d=404&s=%d", size)

        return URLComponents.parseURL(path: path, query: query)
    }


    /// Returs the photon URL for the provided path
    ///
    /// - Parameter siteIconPath: SiteIcon URL (string encoded).
    ///
    private func optimizedPhotonURL(from path: String) -> URL? {
        guard let url = URL(string: path) else {
            return nil
        }

        let size = CGSize(width: SiteIconDefaults.imageSize, height: SiteIconDefaults.imageSize)
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
