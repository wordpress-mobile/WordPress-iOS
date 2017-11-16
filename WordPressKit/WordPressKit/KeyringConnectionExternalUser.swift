import Foundation


/// KeyringConnectionExternalUser represents an additional user account on the
/// external service that could be used other than the default account.
///
open class KeyringConnectionExternalUser: NSObject {
    @objc open var externalID = ""
    @objc open var externalName = ""
    @objc open var externalCategory = ""
    @objc open var externalProfilePicture = ""
}
