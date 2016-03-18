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
    public func uploadImage(image: UIImage, completion: ((success: Bool, error: NSError?) -> ())?) {
        
    }
    
    
    // MARK: - Private Constants
    private let endpointURL = "https://api.gravatar.com/v1/upload-image"
}
