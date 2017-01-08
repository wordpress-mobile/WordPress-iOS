import Foundation


/// KeyringConnection represents a keyring connected to a particular external service.
/// We only rarely need keyring data and we don't really need to persist it. For these
/// reasons KeyringConnection is treated like a model, even though it is not an NSManagedObject,
/// but also treated like it is a Remote Object.
///
open class KeyringConnection: NSObject {
    open var additionalExternalUsers = [KeyringConnectionExternalUser]()
    open var dateIssued = Date()
    open var dateExpires: Date? = nil
    open var externalID = "" // Some services uses strings for their IDs
    open var externalName = ""
    open var externalDisplay = ""
    open var externalProfilePicture = ""
    open var label = ""
    open var keyringID: NSNumber = 0
    open var refreshURL = ""
    open var service = ""
    open var status = ""
    open var type = ""
    open var userID: NSNumber = 0
}
