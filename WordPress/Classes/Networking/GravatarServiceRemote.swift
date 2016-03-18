import Foundation


///
///
public class GravatarServiceRemote : ServiceRemoteREST
{
    ///
    //
    public override init?(api: WordPressComApi!) {
        super.init(api: api)
        if api == nil {
            return nil
        }
    }
    
    ///
    ///
    public func uploadImage(image: UIImage) {
        
    }
    
    
    // MARK: - Private Constants
    private let endpointURL = "https://api.gravatar.com/v1/upload-image"
}
