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
    /// -   Parameters:
    ///     -   email: the user's email
    ///     -   rating: expected image rating
    ///     -   policy: NSURLRequest's Cache Policy. Useful to force reload an image, that might have been changed.
    ///
    func downloadGravatarWithEmail(email : String, rating : GravatarRatings, policy : NSURLRequestCachePolicy)
    {
        downloadGravatarWithEmail(email, placeholderImage : GravatarDefaults.placeholder, rating: rating, policy: policy)
    }
    
    /// Downloads and sets the User's Gravatar, given his email.
    ///
    /// -   Parameters:
    ///     -   email: the user's email
    ///     -   placeholderImage: Image to be used as Placeholder
    ///     -   rating: expected image rating
    ///     -   policy: NSURLRequest's Cache Policy. Useful to force reload an image, that might have been changed.
    ///
    func downloadGravatarWithEmail(email : String,
                                   placeholderImage : UIImage       = GravatarDefaults.placeholder,
                                   rating : GravatarRatings         = GravatarDefaults.rating,
                                   policy : NSURLRequestCachePolicy = GravatarDefaults.policy)
    {

        let targetSize = gravatarDefaultSize()
        let targetURL = gravatarUrlForEmail(email, size: targetSize, rating: rating.stringValue())
        
        let request = NSMutableURLRequest(URL: targetURL!)
        request.cachePolicy = policy

        setImageWithURLRequest(request, placeholderImage: placeholderImage, success: nil, failure: nil)
    }
    
    /// Sets an Image Override in the AFNetworking's Private Cache.
    /// Note: *WHY* is this required?. *WHY* life has to be so complicated?, is the universe against us?
    ///
    /// RE: This has been implemented as a workaround. During Upload, we want any async calls made to
    /// the `downloadGravatar` API to return the "Fresh" image.
    ///
    /// Hope buddah, and the code reviewer, can forgive me for this hack.
    ///
    func overrideGravatarImageCache(image: UIImage, rating: GravatarRatings, email: String)
    {
        let targetSize = gravatarDefaultSize()
        let targetURL = gravatarUrlForEmail(email, size: targetSize, rating: rating.stringValue())
        
        let request = NSURLRequest(URL: targetURL!)
        
        self.dynamicType.sharedImageCache().cacheImage(image, forRequest: request)
    }
    
    
    
    // MARK: - Private Helpers
    
    /// Private helper structure: contains the default Gravatar parameters
    ///
    private struct GravatarDefaults {
        static let placeholder = UIImage(named: "gravatar.png")!
        static let size = 80
        static let rating = GravatarRatings.G
        static let policy = NSURLRequestCachePolicy.UseProtocolCachePolicy
    }
    
    /// Returns the Gravatar URL, for a given email, with the specified size + rating.
    ///
    /// -   Parameters:
    ///     - email: the user's email
    ///     - size: required download size
    ///     - rating: image rating filtering
    ///
    /// -   Returns: Gravatar's URL
    ///
    private func gravatarUrlForEmail(email: String, size: NSInteger, rating: String) -> NSURL?
    {
        let targetURL = String(format: "%@/%@?d=404&s=%d&r=%@", WPGravatarBaseURL, email.md5(), size, rating)
        return NSURL(string: targetURL)
    }
    
    /// Returns the required gravatar size. If the current view's size is zero, falls back to the default size.
    ///
    private func gravatarDefaultSize() -> Int
    {
        guard CGSizeEqualToSize(bounds.size, CGSizeZero) == false else {
            return GravatarDefaults.size
        }

        let targetSize = max(bounds.width, bounds.height) * UIScreen.mainScreen().scale
        return Int(targetSize)
    }
}
