import Foundation


/// KeyringConnection represents a keyring connected to a particular external service.
/// We only rarely need keyring data and we don't really need to persist it. For these
/// reasons KeyringConnection is treated like a model, even though it is not an NSManagedObject,
/// but also treated like it is a Remote Object.
///
public class KeyringConnection : NSObject
{
    public var additionalExternalUsers = [KeyringConnectionExternalUser]()
    public var dateIssued = NSDate()
    public var dateExpires:NSDate? = nil
    public var externalID = "" // Some services uses strings for their IDs
    public var externalName = ""
    public var externalDisplay = ""
    public var externalProfilePicture = ""
    public var label = ""
    public var keyringID:NSNumber = 0
    public var refreshURL = ""
    public var service = ""
    public var status = ""
    public var type = ""
    public var userID:NSNumber = 0
}
