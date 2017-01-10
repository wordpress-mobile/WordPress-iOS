import Foundation


/// KeyringConnectionExternalUser represents an additional user account on the
/// external service that could be used other than the default account.
///
open class KeyringConnectionExternalUser: NSObject {
    open var externalID = ""
    open var externalName = ""
    open var externalCategory = ""
    open var externalProfilePicture = ""
}
