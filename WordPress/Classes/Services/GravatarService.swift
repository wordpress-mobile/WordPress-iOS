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
        accountToken    = mainAccount?.restApi.authToken
        accountEmail    = mainAccount?.email
        
        guard accountEmail?.isEmpty == false && accountToken?.isEmpty == false else {
            return nil
        }
    }
    
    
    /// This method hits the Gravatar Endpoint, and uploads a new image, to be used as profile.
    ///
    /// - Parameters:
    ///     - image: The new Gravatar Image, to be uploaded
    ///     - completion: An optional closure to be executed on completion.
    ///
    public func uploadImage(image: UIImage, completion: ((error: NSError?) -> ())? = nil) {
        let remote = GravatarServiceRemote(accountToken: accountToken, accountEmail: accountEmail)
        remote.uploadImage(image) { (error) in
            if let theError = error {
                DDLogSwift.logError("GravatarService.uploadImage Error: \(theError)")
            } else {
                DDLogSwift.logInfo("GravatarService.uploadImage Success!")
            }
            
            completion?(error: error)
        }
    }
    
    
    // MARK: - Private Properties
    private let accountToken : String!
    private let accountEmail : String!
}
