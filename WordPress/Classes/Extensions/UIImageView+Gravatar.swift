import Foundation

/// UIImageView Helper Methods that allow us to download a Gravatar, given the User's Email
///
extension UIImageView {
    /// Default name string for the blavatar
    struct Blavatar {
        static let defaultImageName = "blavatar-default"
        static let defaultSize = 40
    }

    /// Helper Enum that specifies all of the available Gravatar Image Ratings
    /// TODO: Convert into a pure Swift String Enum. It's done this way to maintain ObjC Compatibility
    ///
    @objc
    public enum GravatarRatings: Int {
        case g
        case pg
        case r
        case x

        func stringValue() -> String {
            switch self {
                case .g:    return "g"
                case .pg:   return "pg"
                case .r:    return "r"
                case .x:    return "x"
            }
        }
    }

    /// Downloads and sets the User's Gravatar, given his email.
    /// TODO: This is a convenience method. Please, remove once all of the code has been migrated over to Swift.
    ///
    /// - Parameters:
    ///     - email: the user's email
    ///     - rating: expected image rating
    ///
    @objc func downloadGravatarWithEmail(_ email: String, rating: GravatarRatings) {
        downloadGravatarWithEmail(email, rating: rating, placeholderImage: GravatarDefaults.placeholderImage)
    }

    /// Downloads and sets the User's Gravatar, given his email.
    ///
    /// - Parameters:
    ///     - email: the user's email
    ///     - rating: expected image rating
    ///     - placeholderImage: Image to be used as Placeholder
    ///
    @objc func downloadGravatarWithEmail(_ email: String, rating: GravatarRatings = GravatarDefaults.rating, placeholderImage: UIImage) {
        let targetSize = gravatarDefaultSize()
        let targetURL = gravatarUrlForEmail(email, size: targetSize, rating: rating.stringValue())
        let targetRequest = URLRequest(url: targetURL!)

        setImageWith(targetRequest, placeholderImage: placeholderImage, success: nil, failure: nil)
    }

    /// Downloads the provided Gravatar.
    ///
    /// - Parameters:
    ///     - gravatar: the user's Gravatar
    ///     - placeholder: Image to be used as Placeholder
    ///     - animate: enable/disable fade in animation
    ///     - failure: Callback block to be invoked when an error occurs while fetching the Gravatar image
    ///
    func downloadGravatar(_ gravatar: Gravatar?, placeholder: UIImage, animate: Bool, failure: ((Error?) -> ())? = nil) {
        guard let gravatar = gravatar else {
            self.image = placeholder
            return
        }

        // Starting with iOS 10, it seems `initWithCoder` uses a default size
        // of 1000x1000, which was messing with our size calculations for gravatars
        // on newly created table cells.
        // Calling `layoutIfNeeded()` forces UIKit to calculate the actual size.
        layoutIfNeeded()

        let size = Int(ceil(frame.width * UIScreen.main.scale))
        let url = gravatar.urlWithSize(size)

        self.downloadImage(url,
                           placeholderImage: placeholder,
                           success: { image in
                            guard image != self.image else {
                                return
                            }

                            self.image = image
                            if animate {
                                self.fadeInAnimation()
                            }
        }, failure: { error in
            failure?(error)
        })
    }

    /// Sets an Image Override in both, AFNetworking's Private Cache + NSURLCache
    ///
    /// Note I:
    /// *WHY* is this required?. *WHY* life has to be so complicated?, is the universe against us?
    /// This has been implemented as a workaround. During Upload, we want any async calls made to the
    /// `downloadGravatar` API to return the "Fresh" image.
    ///
    /// Note II:
    /// We cannot just clear NSURLCache, since the helper that's supposed to do that, is broken since iOS 8.
    /// Ref: Ref: http://blog.airsource.co.uk/2014/10/11/nsurlcache-ios8-broken/
    ///
    /// P.s.:
    /// Hope buddah, and the code reviewer, can forgive me for this hack.
    ///
    @objc func overrideGravatarImageCache(_ image: UIImage, rating: GravatarRatings, email: String) {
        guard let targetURL = gravatarUrlForEmail(email, size: gravatarDefaultSize(), rating: rating.stringValue()) else {
            return
        }

        let request = URLRequest(url: targetURL)

        type(of: self).sharedImageDownloader().imageCache?.removeImageforRequest(request, withAdditionalIdentifier: nil)
        type(of: self).sharedImageDownloader().imageCache?.add(image, for: request, withAdditionalIdentifier: nil)

        // Remove all cached responses - removing an individual response does not work since iOS 7.
        // This feels hacky to do but what else can we do...
        let sessionConfiguration = type(of: self).sharedImageDownloader().sessionManager.value(forKey: "sessionConfiguration") as? URLSessionConfiguration
        sessionConfiguration?.urlCache?.removeAllCachedResponses()
    }

    /// Sets the provided icon as content
    ///
    /// Parameters:
    ///  - siteIcon: string description of the site's icon
    ///
    @objc func setImageWithSiteIcon(_ siteIcon: String) {
        let blavatarDefaultImage = UIImage(named: Blavatar.defaultImageName)
        setImageWithSiteIcon(siteIcon, placeholderImage: blavatarDefaultImage)
    }

    /// Sets the provided icon as content
    ///
    /// Parameters:
    ///  - siteIcon: string description of the site's icon
    ///  - placeholderImage: the image to be used as a placeholder
    ///
    @objc func setImageWithSiteIcon(_ siteIcon: String, placeholderImage: UIImage?) {
        guard let url = URLWithSiteIcon(siteIcon) else {
            return
        }

        setImageWith(url, placeholderImage: placeholderImage)
    }

    /// Sets the blog's icon as content
    ///
    /// Parameters:
    ///  - blog: reference to the source blog
    @objc func setImageWithSiteIcon(for blog: Blog) {
        let blavatarDefaultImage = UIImage(named: Blavatar.defaultImageName)
        setImageWithSiteIcon(for: blog, placeholderImage: blavatarDefaultImage)
    }

    /// Sets the blog's icon as content
    ///
    /// Parameters:
    ///  - blog: reference to the source blog
    ///  - placeholderImage: the placeholder
    @objc func setImageWithSiteIcon(for blog: Blog, placeholderImage: UIImage?) {
        if blog.isHostedAtWPcom && blog.isPrivate() {
            setImageWithPrivateSiteIcon(siteIcon: blog.icon, placeholderImage: placeholderImage)
        } else {
            setImageWithSiteIcon(blog.icon!, placeholderImage: placeholderImage)
        }
    }

    /// Sets the content with the default blavatar image
    @objc func setDefaultSiteIconImage() {
        image = UIImage(named: Blavatar.defaultImageName)
    }
    // MARK: - Private Helpers

    /// Returns the Gravatar URL, for a given email, with the specified size + rating.
    ///
    /// - Parameters:
    ///     - email: the user's email
    ///     - size: required download size
    ///     - rating: image rating filtering
    ///
    /// - Returns: Gravatar's URL
    ///
    fileprivate func gravatarUrlForEmail(_ email: String, size: Int, rating: String) -> URL? {
        let sanitizedEmail = email
            .lowercased()
            .trimmingCharacters(in: CharacterSet.whitespaces)
        let targetURL = String(format: "%@/%@?d=404&s=%d&r=%@", WPGravatarBaseURL, sanitizedEmail.md5(), size, rating)
        return URL(string: targetURL)
    }

    /// Returns the required gravatar size. If the current view's size is zero, falls back to the default size.
    ///
    fileprivate func gravatarDefaultSize() -> Int {
        guard bounds.size.equalTo(CGSize.zero) == false else {
            return GravatarDefaults.imageSize
        }

        let targetSize = max(bounds.width, bounds.height) * UIScreen.main.scale
        return Int(targetSize)
    }

    /// Private helper structure: contains the default Gravatar parameters
    ///
    fileprivate struct GravatarDefaults {
        static let placeholderImage = UIImage(named: "gravatar.png")!
        static let imageSize = 80
        static let rating = GravatarRatings.g
    }

    /// Returs the proper download URL for the provided icon
    ///
    /// Parameters:
    ///  - siteIcon: the icon's path
    fileprivate func URLWithSiteIcon(_ siteIcon: String) -> URL? {
        if isPhotonURL(siteIcon) || self.isWordPressComFilesURL(siteIcon) {
            return siteIconURLForSiteIconUrl(siteIcon)
        }

        if isBlavatarURL(siteIcon) {
            return blavatarURLForBlavatarURL(siteIcon)
        }

        return URLForResizedImageURL(siteIcon)
    }

    /// Returs the download URL for a square icon with a size of sizeForBlavatarDownload
    ///
    /// Parameters:
    ///  - path: the icon's path
    fileprivate func siteIconURLForSiteIconUrl(_ path: String) -> URL? {
        let size = sizeForBlavatarDownload()
        return urlForUrlWithFormat(path, format: String(format: "w=%d&h=%d", size, size))
    }

    /// Sets the blog's icon as content, for private blogs
    ///
    /// Parameters:
    ///  - siteIcon: the icon's path
    ///  - placeholderImage: the placeholder
    fileprivate func setImageWithPrivateSiteIcon(siteIcon: String?, placeholderImage: UIImage?) {
        guard let icon = siteIcon else {
            return
        }

        guard let imageRequest = PrivateSiteURLProtocol.requestForPrivateSite(from: URLWithSiteIcon(icon)) else {
            return
        }

        setImageWith(imageRequest, placeholderImage: placeholderImage, success: nil, failure: nil)
    }

    // MARK: - Private Photon Helpers
    /// Returs the photon URL for the provided path
    ///
    /// Parameters:
    ///  - urlString: source URL
    fileprivate func URLForResizedImageURL(_ urlString: String) -> URL? {
        let size = CGSize(width: Blavatar.defaultSize, height: Blavatar.defaultSize)
        guard let url = URL(string: urlString) else {
            return nil
        }
        return PhotonImageURLHelper.photonURL(with: size, forImageURL: url)
    }

    // Possible matches are "i0.wp.com", "i1.wp.com" & "i2.wp.com" -> https://developer.wordpress.com/docs/photon/
    fileprivate func isPhotonURL(_ path: String) -> Bool {
        return path.contains(".wp.com")
    }

    // MARK: - Blavatar Private Methods
    /// Returs the icon URL corresponding to the provided path
    ///
    /// Parameters:
    ///  - path: source icon path
    fileprivate func blavatarURLForBlavatarURL(_ path: String) -> URL? {
        let size = sizeForBlavatarDownload()
        return urlForUrlWithFormat(path, format: String(format: "d=404&s=%d", size))
    }

    /// Returns the download size for a blavatar
    fileprivate func sizeForBlavatarDownload() -> Int {
        var size = Blavatar.defaultSize
        size *= Int(UIScreen.main.scale)

        return size
    }

    // MARK: - Other helpers
    fileprivate func isWordPressComFilesURL(_ path: String) -> Bool {
        return path.contains(".files.wordpress.com")
    }

    fileprivate func isBlavatarURL(_ path: String) -> Bool {
        return path.contains("gravatar.com/blavatar")
    }

    fileprivate func urlForUrlWithFormat(_ path: String, format: String) -> URL? {
        guard var urlComponents = URLComponents(string: path) else {
            return nil
        }

        urlComponents.query = format
        return urlComponents.url
    }
}
