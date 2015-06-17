import Foundation


public class NotificationsService : NSObject, LocalCoreDataService
{
    /**
    *  @details     Designated Initializer
    *  @param       managedObjectContext    A Reference to the MOC that should be used to interact with
    *                                       the Core Data Persistent Store.
    */
    public required init(managedObjectContext: NSManagedObjectContext) {
        super.init()
        self.managedObjectContext       = managedObjectContext
        self.notificationsServiceRemote = NotificationsServiceRemote(api: apiForRequest())
    }
    
    /**
    *  @details     Helper method to get the WordPress.com REST Api, if any
    *  @returns     WordPressComApi instance, if applicable, or nil.
    */
    private func apiForRequest() -> WordPressComApi? {
        let accountService = AccountService(managedObjectContext: managedObjectContext)
        let unwrappedRestApi = accountService.defaultWordPressComAccount()?.restApi
        
        if unwrappedRestApi != nil && unwrappedRestApi?.hasCredentials() == true {
            return unwrappedRestApi!
        }

        return nil
    }
    
    // MARK: - Private Internal Properties
    private var managedObjectContext :      NSManagedObjectContext!
    private var notificationsServiceRemote: NotificationsServiceRemote?
}
