import Foundation


/// This Service exposes all of the valid operations we can execute, to interact with the Gravatar Service.
///
open class GravatarService {
    /// Designated Initializer
    ///
    /// - Parameter context: The Core Data context that should be used by the service.
    ///
    /// - Returns: nil if there's no valid WordPressCom Account available.
    ///
    public init?(context: NSManagedObjectContext) {
        let mainAccount = AccountService(managedObjectContext: context).defaultWordPressComAccount()
        accountToken    = mainAccount?.authToken
        accountEmail    = mainAccount?.email
            .trimmingCharacters(in: CharacterSet.whitespaces)
            .lowercased()

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
    open func uploadImage(_ image: UIImage, completion: ((_ error: NSError?) -> ())? = nil) {
        let remote = gravatarServiceRemoteForAccountToken(accountToken: accountToken, andAccountEmail: accountEmail)
        remote.uploadImage(image, accountEmail: accountEmail, accountToken: accountToken) { (error) in
            if let theError = error {
                DDLogSwift.logError("GravatarService.uploadImage Error: \(theError)")
            } else {
                DDLogSwift.logInfo("GravatarService.uploadImage Success!")
            }

            completion?(error)
        }
    }

    func gravatarServiceRemoteForAccountToken(accountToken: String, andAccountEmail accountEmail: String) -> GravatarServiceRemote {
        return GravatarServiceRemote()
    }

    // MARK: - Private Properties
    fileprivate let accountToken: String!
    fileprivate let accountEmail: String!
}
