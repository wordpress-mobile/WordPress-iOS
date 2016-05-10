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
    let emailPendingAddress: String? // new_user_email
    let emailPendingChange: Bool // user_email_change_pending
    let primarySiteID: Int  // primary_site_ID
    let webAddress: String  // user_URL
    let language: String    // language
}

extension AccountSettings {
    init(managed: ManagedAccountSettings) {
        firstName = managed.firstName
        lastName = managed.lastName
        displayName = managed.displayName
        aboutMe = managed.aboutMe

        username = managed.username
        email = managed.email
        emailPendingAddress = managed.emailPendingAddress
        emailPendingChange = managed.emailPendingChange
        primarySiteID = managed.primarySiteID.integerValue
        webAddress = managed.webAddress
        language = managed.language
    }

    var emailForDisplay : String {
        let pendingEmail = emailPendingAddress?.nonEmptyString() ?? email
        return emailPendingChange ? pendingEmail : email
    }
}
