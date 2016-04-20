import Foundation


/// KeyringConnectionExternalUser represents an additional user account on the
/// external service that could be used other than the default account.
///
public class KeyringConnectionExternalUser : NSObject
{
    public var externalID = ""
    public var externalName = ""
    public var externalCategory = ""
    public var externalProfilePicture = ""
}
