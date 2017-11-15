import Foundation


/// KeyringConnection represents a keyring connected to a particular external service.
/// We only rarely need keyring data and we don't really need to persist it. For these
/// reasons KeyringConnection is treated like a model, even though it is not an NSManagedObject,
/// but also treated like it is a Remote Object.
///
open class KeyringConnection: NSObject {
    @objc open var additionalExternalUsers = [KeyringConnectionExternalUser]()
    @objc open var dateIssued = Date()
    @objc open var dateExpires: Date? = nil
    @objc open var externalID = "" // Some services uses strings for their IDs
    @objc open var externalName = ""
    @objc open var externalDisplay = ""
    @objc open var externalProfilePicture = ""
    @objc open var label = ""
    @objc open var keyringID: NSNumber = 0
    @objc open var refreshURL = ""
    @objc open var service = ""
    @objc open var status = ""
    @objc open var type = ""
    @objc open var userID: NSNumber = 0
}
