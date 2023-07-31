import Foundation
import WordPressAuthenticator


/// A simple container for the user info shown on the login epilogue screen.
///
public struct LoginEpilogueUserInfo {
    var username = ""
    var fullName = ""
    var email = ""
    var gravatarUrl: String?
    var credentials: AuthenticatorCredentials?

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

    /// Updates the Epilogue properties, given a GravatarProfile instance.
    ///
    mutating func update(with profile: GravatarProfile) {
        gravatarUrl = profile.thumbnailUrl
        fullName = profile.displayName
    }

    /// Updates the Epilogue properties, given a SocialService instance.
    ///
    mutating func update(with socialUser: SocialUser) {
        fullName = socialUser.fullName
        email = socialUser.email
    }
}
