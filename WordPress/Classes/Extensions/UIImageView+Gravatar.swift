import Foundation


/// UIImageView Helper Methods that allow us to download a gravar, given the User's Email
///
extension UIImageView
{
    /// Helper Enum that specifies all of the available Gravatar Image Ratings
    /// TODO: Convert into a pure Swift String Enum. It's done this way to maintain ObjC Compatibility
    ///
    @objc
    public enum GravatarRatings : Int {
        case G
        case PG
        case R
        case X

        func stringValue() -> String {
            switch self {
                case .G:    return "g"
                case .PG:   return "pg"
                case .R:    return "r"
                case .X:    return "x"
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
    func downloadGravatarWithEmail(email : String, rating : GravatarRatings) {
        downloadGravatarWithEmail(email, rating: rating, placeholderImage : GravatarDefaults.placeholderImage)
    }

    /// Downloads and sets the User's Gravatar, given his email.
    ///
    /// - Parameters:
    ///     - email: the user's email
    ///     - rating: expected image rating
    ///     - placeholderImage: Image to be used as Placeholder
    ///
    func downloadGravatarWithEmail(email : String, rating : GravatarRatings = GravatarDefaults.rating, placeholderImage : UIImage) {
        let targetSize = gravatarDefaultSize()
        let targetURL = gravatarUrlForEmail(email, size: targetSize, rating: rating.stringValue())
        let targetRequest = NSURLRequest(URL: targetURL!)

        setImageWithURLRequest(targetRequest, placeholderImage: placeholderImage, success: nil, failure: nil)
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
    func overrideGravatarImageCache(image: UIImage, rating: GravatarRatings, email: String) {
        guard let targetURL = gravatarUrlForEmail(email, size: gravatarDefaultSize(), rating: rating.stringValue()) else {
            return
        }

        let request = NSURLRequest(URL: targetURL)


        self.dynamicType.sharedImageDownloader().imageCache?.addImage(image, forRequest: request, withAdditionalIdentifier: nil)
        NSURLCache.sharedURLCache().cacheImage(image, forRequest: request)
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
    private func gravatarUrlForEmail(email: String, size: NSInteger, rating: String) -> NSURL? {
        let targetURL = String(format: "%@/%@?d=404&s=%d&r=%@", WPGravatarBaseURL, email.md5(), size, rating)
        return NSURL(string: targetURL)
    }

    /// Returns the required gravatar size. If the current view's size is zero, falls back to the default size.
    ///
    private func gravatarDefaultSize() -> Int {
        guard CGSizeEqualToSize(bounds.size, CGSizeZero) == false else {
            return GravatarDefaults.imageSize
        }

        let targetSize = max(bounds.width, bounds.height) * UIScreen.mainScreen().scale
        return Int(targetSize)
    }

    /// Private helper structure: contains the default Gravatar parameters
    ///
    private struct GravatarDefaults {
        static let placeholderImage = UIImage(named: "gravatar.png")!
        static let imageSize = 80
        static let rating = GravatarRatings.G
    }
}
