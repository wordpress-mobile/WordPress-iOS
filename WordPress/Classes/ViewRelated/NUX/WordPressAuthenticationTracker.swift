import Foundation


// MARK: - Relays WordPressAutentication Flow Events over to WPAppAnalytics
//
class WordPressAuthenticationTracker {

    // MARK: - Deinitializers
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    /// Starts Listening for Authentication Flow Events
    ///
    func startListeningToAuthenticationEvents() {
        NotificationCenter.default.addObserver(self, selector: #selector(didReceive), name: .wordpressAuthenticationFlowEvent, object: nil)
    }
}


// MARK: - Internal Methods
//
extension WordPressAuthenticationTracker {

    /// Relays WordPressAuthenticator.Event Notifications into Automattic Tracks.
    ///
    @objc
    func didReceive(note: NSNotification) {
        guard let event = note.object as? WordPressAuthenticator.Event else {
            return
        }

        switch event {
        case .createAccountInitiated:
            WPAppAnalytics.track(.createAccountInitiated)
        case .loginAutoFillCredentialsFilled:
            WPAppAnalytics.track(.loginAutoFillCredentialsFilled)
        case .loginAutoFillCredentialsUpdated:
            WPAppAnalytics.track(.loginAutoFillCredentialsUpdated)
        case .loginEmailFormViewed:
            WPAppAnalytics.track(.loginEmailFormViewed)
        case .loginEpilogueViewed:
            WPAppAnalytics.track(.loginEpilogueViewed)
        case .loginFailed(let error):
            WPAppAnalytics.track(.loginFailed, error: error)
        case .loginFailedToGuessXMLRPC(let error):
            WPAppAnalytics.track(.loginFailedToGuessXMLRPC, error: error)
        case .loginForgotPasswordClicked:
            WPAppAnalytics.track(.loginForgotPasswordClicked)
        case .loginMagicLinkFailed:
            WPAppAnalytics.track(.loginMagicLinkFailed)
        case .loginMagicLinkOpenEmailClientViewed:
            WPAppAnalytics.track(.loginMagicLinkOpenEmailClientViewed)
        case .loginMagicLinkRequested:
            WPAppAnalytics.track(.loginMagicLinkRequested)
        case .loginMagicLinkRequestFormViewed:
            WPAppAnalytics.track(.loginMagicLinkRequestFormViewed)
        case .loginMagicLinkExited:
            WPAppAnalytics.track(.loginMagicLinkExited)
        case .loginMagicLinkOpened:
            WPAppAnalytics.track(.loginMagicLinkOpened)
        case .loginMagicLinkSucceeded:
            WPAppAnalytics.track(.loginMagicLinkSucceeded)
        case .loginPasswordFormViewed:
            WPAppAnalytics.track(.loginPasswordFormViewed)
        case .loginProloguePaged:
            WPAppAnalytics.track(.loginProloguePaged)
        case .loginPrologueViewed:
            WPAppAnalytics.track(.loginPrologueViewed)
        case .loginSocialAccountsNeedConnecting:
            WPAppAnalytics.track(.loginSocialAccountsNeedConnecting)
        case .loginSocial2faNeeded:
            WPAppAnalytics.track(.loginSocial2faNeeded)
        case .loginSocialButtonClick:
            WPAppAnalytics.track(.loginSocialButtonClick)
        case .loginSocialButtonFailure(let error?):
            WPAppAnalytics.track(.loginSocialButtonFailure, error: error)
        case .loginSocialButtonFailure:
            WPAppAnalytics.track(.loginSocialButtonFailure)
        case .loginSocialConnectSuccess:
            WPAppAnalytics.track(.loginSocialConnectSuccess)
        case .loginSocialConnectFailure(let error):
            WPAppAnalytics.track(.loginSocialConnectFailure, error: error)
        case .loginSocialErrorUnknownUser:
            WPAppAnalytics.track(.loginSocialErrorUnknownUser)
        case .loginSocialSuccess:
            WPAppAnalytics.track(.loginSocialSuccess)
        case .loginTwoFactorFormViewed:
            WPAppAnalytics.track(.loginTwoFactorFormViewed)
        case .loginURLFormViewed:
            WPAppAnalytics.track(.loginURLFormViewed)
        case .loginUsernamePasswordFormViewed:
            WPAppAnalytics.track(.loginUsernamePasswordFormViewed)
        case .onePasswordFailed:
            WPAppAnalytics.track(.onePasswordFailed)
        case .onePasswordLogin:
            WPAppAnalytics.track(.onePasswordLogin)
        case .openedLogin:
            WPAppAnalytics.track(.openedLogin)
        case .signupMagicLinkOpenEmailClientViewed:
            WPAppAnalytics.track(.signupMagicLinkOpenEmailClientViewed)
        case .signedIn(let properties):
            WPAppAnalytics.track(.signedIn, withProperties: properties)
        case .twoFactorCodeRequested:
            WPAppAnalytics.track(.twoFactorCodeRequested)
        }
    }
}
