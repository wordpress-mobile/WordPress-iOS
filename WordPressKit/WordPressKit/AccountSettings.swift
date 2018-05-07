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
    public let tracksOptOut: Bool

    public init(firstName: String,
                lastName: String,
                displayName: String,
                aboutMe: String,
                username: String,
                email: String,
                emailPendingAddress: String?,
                emailPendingChange: Bool,
                primarySiteID: Int,
                webAddress: String,
                language: String,
                tracksOptOut: Bool) {
        self.firstName = firstName
        self.lastName = lastName
        self.displayName = displayName
        self.aboutMe = aboutMe
        self.username = username
        self.email = email
        self.emailPendingAddress = emailPendingAddress
        self.emailPendingChange = emailPendingChange
        self.primarySiteID = primarySiteID
        self.webAddress = webAddress
        self.language = language
        self.tracksOptOut = tracksOptOut
    }
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
    case tracksOptOut(Bool)

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
        case .tracksOptOut(let value):
            return String(value)
        }
    }
}

public typealias AccountSettingsChangeWithString = (String) -> AccountSettingsChange
public typealias AccountSettingsChangeWithInt = (Int) -> AccountSettingsChange
