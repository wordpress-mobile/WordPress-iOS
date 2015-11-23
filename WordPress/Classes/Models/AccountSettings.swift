import Foundation

struct AccountSettings {
    // MARK: - My Profile
    let firstName: String   // first_name
    let lastName: String    // last_name
    let displayName: String // display_name
    let aboutMe: String     // description

    // MARK: - Account Settings
    let username: String    // user_login
    let email: String       // user_email
    let primarySiteID: Int  // primary_site_ID
    let webAddress: String  // user_URL
    let language: String    // language
}

class ManagedAccountSettings: NSManagedObject {
    @NSManaged var firstName: String
    @NSManaged var lastName: String
    @NSManaged var displayName: String
    @NSManaged var aboutMe: String

    @NSManaged var username: String
    @NSManaged var email: String
    @NSManaged var primarySiteID: Int
    @NSManaged var webAddress: String
    @NSManaged var language: String

    @NSManaged var account: WPAccount

    func updateWith(accountSettings: AccountSettings) {
        firstName = accountSettings.firstName
        lastName = accountSettings.lastName
        displayName = accountSettings.displayName
        aboutMe = accountSettings.aboutMe

        username = accountSettings.username
        email = accountSettings.email
        primarySiteID = accountSettings.primarySiteID
        webAddress = accountSettings.webAddress
        language = accountSettings.language
    }
}

extension AccountSettings {
    init(managed: ManagedAccountSettings) {
        firstName = managed.firstName
        lastName = managed.lastName
        displayName = managed.displayName
        aboutMe = managed.aboutMe

        username = managed.username
        email = managed.email
        primarySiteID = managed.primarySiteID
        webAddress = managed.webAddress
        language = managed.language
    }
}