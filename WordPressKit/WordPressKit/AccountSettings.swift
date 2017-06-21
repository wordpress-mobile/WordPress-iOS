import Foundation

public struct AccountSettings {
    // MARK: - My Profile
    public let firstName: String   // first_name
    public let lastName: String    // last_name
    public let displayName: String // display_name
    public let aboutMe: String     // description

    // MARK: - Account Settings
    public let username: String    // user_login
    public let email: String       // user_email
    public let emailPendingAddress: String? // new_user_email
    public let emailPendingChange: Bool // user_email_change_pending
    public let primarySiteID: Int  // primary_site_ID
    public let webAddress: String  // user_URL
    public let language: String    // language
}

public enum AccountSettingsChange {
    case firstName(String)
    case lastName(String)
    case displayName(String)
    case aboutMe(String)
    case email(String)
    case emailRevertPendingChange
    case primarySite(Int)
    case webAddress(String)
    case language(String)

    var stringValue: String {
        switch self {
        case .firstName(let value):
            return value
        case .lastName(let value):
            return value
        case .displayName(let value):
            return value
        case .aboutMe(let value):
            return value
        case .email(let value):
            return value
        case .emailRevertPendingChange:
            return String(false)
        case .primarySite(let value):
            return String(value)
        case .webAddress(let value):
            return value
        case .language(let value):
            return value
        }
    }
}

public typealias AccountSettingsChangeWithString = (String) -> AccountSettingsChange
public typealias AccountSettingsChangeWithInt = (Int) -> AccountSettingsChange
