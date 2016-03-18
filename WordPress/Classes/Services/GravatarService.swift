import Foundation


/// This class encapsulates all of the interaction with the Gravatar endpoint.
///
public class GravatarService
{
    ///
    //
    public init?(context: NSManagedObjectContext) {
        let mainAccount = AccountService(managedObjectContext: context).defaultWordPressComAccount()
        remoteApi       = mainAccount?.restApi
        accountEmail    = mainAccount?.email
        
        guard remoteApi != nil && remoteApi?.hasCredentials() == true else {
            return nil
        }
    }
    
    ///
    ///
    public func uploadImage(image: UIImage) {
        
    }
    
    
    // MARK: - Private Properties
    private let remoteApi       : WordPressComApi?
    private let accountEmail    : String?
}
