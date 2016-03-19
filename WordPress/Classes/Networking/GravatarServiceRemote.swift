import Foundation


/// This ServiceRemote encapsulates all of the interaction with the Gravatar endpoint.
///
public class GravatarServiceRemote : ServiceRemoteREST
{
    /// Designated Initializer
    ///
    /// - Parameters:
    ///     - api: A valid WordPressComApi instance, to be used by the service layer.
    ///
    public override init(api: WordPressComApi) {
        super.init(api: api)
    }
    
    
    /// This method hits the Gravatar Endpoint, and uploads a new image, to be used as profile.
    ///
    /// - Parameters:
    ///     - image: The new Gravatar Image, to be uploaded
    ///     - completion: An optional closure to be executed on completion.
    ///
    public func uploadImage(image: UIImage, completion: ((error: NSError?) -> ())?) {
        let targetURL       = NSURL(string: gravatarEndpointURL)!
        let request         = NSMutableURLRequest(URL: targetURL)
        request.HTTPMethod  = HTTPPostMethod
        
        let payload         = UIImageJPEGRepresentation(image, defaultCompressionRatio)
        let session         = NSURLSession.sharedSession()
        session.uploadTaskWithRequest(request, fromData: payload) { (data, response, error) in
            completion?(error: error)
        }
    }
    
    
    // MARK: - Private Constants
    private let gravatarEndpointURL     = "https://api.gravatar.com/v1/upload-image"
    private let HTTPPostMethod          = "POST"
    private let defaultCompressionRatio = CGFloat(0.9)
}
