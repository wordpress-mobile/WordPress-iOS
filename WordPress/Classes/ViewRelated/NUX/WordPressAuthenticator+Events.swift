import Foundation


// MARK: - Authentication Flow Event. Useful to relay internal Auth events over to activity trackers.
//
public extension WordPressAuthenticator {
    public enum Event {
        case createAccountInitiated
        case createdAccount
        case loginAutoFillCredentialsFilled
        case loginAutoFillCredentialsUpdated
        case loginEmailFormViewed
        case loginEpilogueViewed
        case loginFailed(error: Error)
        case loginFailedToGuessXMLRPC(error: Error)
        case loginForgotPasswordClicked
        case loginMagicLinkFailed
        case loginMagicLinkOpenEmailClientViewed
        case loginMagicLinkRequested
        case loginMagicLinkRequestFormViewed
        case loginMagicLinkExited
        case loginMagicLinkOpened
        case loginMagicLinkSucceeded
        case loginPasswordFormViewed
        case loginProloguePaged
        case loginPrologueViewed
        case loginSocialAccountsNeedConnecting
        case loginSocial2faNeeded
        case loginSocialButtonClick
        case loginSocialButtonFailure(error: Error?)
        case loginSocialConnectSuccess
        case loginSocialConnectFailure(error: Error)
        case loginSocialErrorUnknownUser
        case loginSocialSuccess
        case loginTwoFactorFormViewed
        case loginURLFormViewed
        case loginURLHelpScreenViewed
        case loginUsernamePasswordFormViewed
        case onePasswordFailed
        case onePasswordLogin
        case onePasswordSignup
        case openedLogin
        case signupMagicLinkOpenEmailClientViewed
        case signupMagicLinkOpened
        case signupMagicLinkSucceeded
        case signupMagicLinkFailed
        case signupMagicLinkRequested
        case signupSocialSuccess
        case signedIn(properties: [String: String])
        case twoFactorCodeRequested
    }
}


// MARK: - Internal Helpers
//
extension WordPressAuthenticator {

    /// Posts a `wordpressAuthenticationFlowEvent` notification, containing the specified Event.
    ///
    static func post(event: Event) {
        NotificationCenter.default.post(name: .wordpressAuthenticationFlowEvent, object: event)
    }
}
