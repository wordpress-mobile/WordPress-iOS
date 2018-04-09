import Foundation
import GoogleSignIn


/// A simple container for the user info shown on the login epilogue screen.
///
public struct LoginEpilogueUserInfo {
    var username = ""
    var fullName = ""
    var email = ""
    var gravatarUrl: String?
    var credentials: WordPressCredentials?

    /// Initializes the EpilogueUserInfo with all of the metadata contained within WPAccount.
    ///
    init(account: WPAccount) {
        if let name = account.username {
            username = name
        }
        if let accountEmail = account.email {
            email = accountEmail
        }
        if let displayName = account.displayName {
            fullName = displayName
        }
    }

    /// Initializes the EpilogueUserInfo with all of the metadata contained within UserProfile.
    ///
    init(profile: UserProfile) {
        username = profile.username
        fullName = profile.displayName
        email = profile.email
    }
}


// MARK: - LoginEpilogueUserInfo
//
extension LoginEpilogueUserInfo {

    /// Updates the Epilogue properties, given an UserProfile instance.
    ///
    mutating func update(with profile: UserProfile) {
        username = profile.username
        fullName = profile.displayName
        email = profile.email
    }

    /// Updates the Epilogue properties, given a SocialService instance.
    ///
    mutating func update(with service: SocialService) {
        switch service {
        case .google(let user):
            fullName = user.profile.name
            email = user.profile.email
        }
    }
}
