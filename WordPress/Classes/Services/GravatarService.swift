import Foundation



/// This Service exposes all of the valid operations we can execute, to interact with the Gravatar Service.
///
public class GravatarService
{
    /// Designated Initializer
    ///
    /// - Parameters:
    ///     - context: The Core Data context that should be used by the service.
    ///
    /// - Returns: nil if there's no valid WordPressCom Account available.
    ///
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
        let remote = GravatarServiceRemote(api: remoteApi)
        remote.uploadImage(image) { (success, error) in
            if success {
                return
            }
            
            DDLogSwift.logError("GravatarService.uploadImage Error: \(error)")
        }
    }
    
    
    // MARK: - Private Properties
    private let remoteApi       : WordPressComApi!
    private let accountEmail    : String!
}
