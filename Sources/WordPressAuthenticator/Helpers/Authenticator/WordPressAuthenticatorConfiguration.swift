import WordPressKit

// MARK: - WordPressAuthenticator Configuration
//
public struct WordPressAuthenticatorConfiguration {

    /// WordPress.com Client ID
    ///
    let wpcomClientId: String

    /// WordPress.com Secret
    ///
    let wpcomSecret: String

    /// Client App: Used for Magic Link purposes.
    ///
    let wpcomScheme: String

    /// WordPress.com Terms of Service URL
    ///
    let wpcomTermsOfServiceURL: URL

    /// WordPress.com Base URL for OAuth
    ///
    let wpcomBaseURL: URL

    /// WordPress.com API Base URL
    ///
    let wpcomAPIBaseURL: URL

    /// The URL of a webpage which has details about What is WordPress.com?.
    ///
    /// Displayed in the WordPress.com login page. The button/link will not be displayed if this value is nil.
    ///
    let whatIsWPComURL: URL?

    /// GoogleLogin Client ID
    ///
    let googleLoginClientId: String

    /// GoogleLogin ServerClient ID
    ///
    let googleLoginServerClientId: String

    /// GoogleLogin Callback Scheme
    ///
    let googleLoginScheme: String

    internal var googleClientId: GoogleClientId {
        guard let clientId = GoogleClientId(string: googleLoginClientId) else {
            fatalError("Could not init GoogleClientId from developer provided value.")
        }

        return clientId
    }

    /// UserAgent
    ///
    let userAgent: String

    /// Flag indicating which Log In flow to display.
    /// If enabled, when Log In is selected, a button view is displayed with options.
    /// If disabled, when Log In is selected, the email login view is displayed with alternative options.
    ///
    let showLoginOptions: Bool

    /// Flag indicating if Sign Up UX is enabled for all services.
    ///
    let enableSignUp: Bool

    /// Hint buttons help users complete a step in the unified auth flow. Enabled by default.
    /// If enabled, "Find your site address", "Reset your password", and others will be displayed.
    /// If disabled, none of the hint buttons will appear on the unified auth flows.
    let displayHintButtons: Bool

    /// Flag indicating if the Sign In With Apple option should be displayed.
    ///
    let enableSignInWithApple: Bool

    /// Flag indicating if signing up via Google is enabled.
    /// This only applies to the unified Google flow.
    /// When a user attempts to log in with a nonexistent account:
    ///     If enabled, the user will be redirected to Google signup.
    ///     If disabled, a view is displayed providing the user with other options.
    ///
    let enableSignupWithGoogle: Bool

    /// Flag for the unified login/signup flows.
    /// If disabled, none of the unified flows will display.
    /// If enabled, all unified flows will display.
    ///
    let enableUnifiedAuth: Bool

    /// Flag for the new prologue carousel.
    /// If disabled, displays the old carousel.
    /// If enabled, displays the new carousel.
    let enableUnifiedCarousel: Bool

    /// Flag for the Passkeys, or WebAuthn, login.
    let enablePasskeys: Bool

    /// Flag for the unified login/signup flows.
    /// If disabled, the "Continue With WordPress" button in the login prologue is shown first.
    /// If enabled, the "Enter your existing site address" button in the login prologue is shown first.
    /// Default value is disabled
    let continueWithSiteAddressFirst: Bool

    /// If enabled shows a "Sign in with site credentials" button in `GetStartedViewController` when landing in the screen after entering site address
    ///  Used to enable sign-in to self-hosted sites using WordPress.org credentials.
    ///  Disabled by default
    let enableSiteCredentialsLoginForSelfHostedSites: Bool

    /// If enabled, we will ask for WPCOM login after signing in using .org site credentials.
    ///  Disabled by default
    let isWPComLoginRequiredForSiteCredentialsLogin: Bool

    /// If enabled, a magic link is sent automatically in place of password then fall back to password.
    /// If disabled, password is shown by default with an option to send a magic link.
    let isWPComMagicLinkPreferredToPassword: Bool

    /// If enabled, the alternative magic link action on the password screen is shown as a secondary call-to-action at the bottom.
    /// If disabled, the alternative magic link action on the password screen is shown below the reset password action.
    let isWPComMagicLinkShownAsSecondaryActionOnPasswordScreen: Bool

    /// If enabled, the Prologue screen will display only the entry point for WPCom login and no site address login.
    ///
    let enableWPComLoginOnlyInPrologue: Bool

    /// If enabled, an entry point to the site creation flow will be added to the bottom button of the prologue screen of simplified login.
    ///
    let enableSiteCreation: Bool

    /// If enabled, social login will be display at the bottom of the WPCom login screen.
    ///
    let enableSocialLogin: Bool

    /// If enabled, there will be a border around the email label on the WPCom password screen.
    ///
    let emphasizeEmailForWPComPassword: Bool

    /// The optional instructions for WPCom password.
    ///
    let wpcomPasswordInstructions: String?

    /// If enabled, site discovery will not check for XMLRPC URL.
    ///
    let skipXMLRPCCheckForSiteDiscovery: Bool

    /// If enabled, site address login will not check for XMLRPC URL.
    ///
    let skipXMLRPCCheckForSiteAddressLogin: Bool

    /// If enabled, the library will trigger the delegate method `handleSiteCredentialLogin`
    /// instead of using the XMLRPC API for handling site credential login.
    let enableManualSiteCredentialLogin: Bool

    /// If enabled, the library will not show any alert or inline error message
    /// when site credential login fails.
    /// Instead, the delegate method `handleSiteCredentialLoginFailure` will be called.
    ///
    let enableManualErrorHandlingForSiteCredentialLogin: Bool

    /// Used to determine the `step` value for `unified_login_step` analytics event in `GetStartedViewController`
    ///
    ///  - If disabled `start` will be used as `step` value
    ///     - Disabled by default
    ///  - If enabled, `enter_email_address` will be used as `step` value
    ///     - Custom step value is used because `start` is used in other VCs as well, which doesn't allow us to differentiate between screens.
    ///     - i.e. Some screens have the same `step` and `flow` value. `GetStartedViewController` and `SiteAddressViewController` for example.
    ///
    let useEnterEmailAddressAsStepValueForGetStartedVC: Bool

    /// If enabled, the prologue screen should hide the WPCom login CTA and show only the entry point to site address login.
    ///
    let enableSiteAddressLoginOnlyInPrologue: Bool

    /// If enabled, the prologue screen would display a link for site creation guide.
    ///
    let enableSiteCreationGuide: Bool

    let disableAutofill: Bool

    /// Designated Initializer
    ///
    public init (wpcomClientId: String,
                 wpcomSecret: String,
                 wpcomScheme: String,
                 wpcomTermsOfServiceURL: URL,
                 wpcomBaseURL: URL = WordPressComOAuthClient.WordPressComOAuthDefaultBaseURL,
                 wpcomAPIBaseURL: URL = WordPressComOAuthClient.WordPressComOAuthDefaultApiBaseURL,
                 whatIsWPComURL: URL? = nil,
                 googleLoginClientId: String,
                 googleLoginServerClientId: String,
                 googleLoginScheme: String,
                 userAgent: String,
                 showLoginOptions: Bool = false,
                 enableSignUp: Bool = true,
                 enableSignInWithApple: Bool = false,
                 enableSignupWithGoogle: Bool = false,
                 enableUnifiedAuth: Bool = false,
                 enableUnifiedCarousel: Bool = false,
                 enablePasskeys: Bool = true,
                 displayHintButtons: Bool = true,
                 continueWithSiteAddressFirst: Bool = false,
                 enableSiteCredentialsLoginForSelfHostedSites: Bool = false,
                 isWPComLoginRequiredForSiteCredentialsLogin: Bool = false,
                 isWPComMagicLinkPreferredToPassword: Bool = false,
                 isWPComMagicLinkShownAsSecondaryActionOnPasswordScreen: Bool = false,
                 enableWPComLoginOnlyInPrologue: Bool = false,
                 enableSiteCreation: Bool = false,
                 enableSocialLogin: Bool = false,
                 emphasizeEmailForWPComPassword: Bool = false,
                 wpcomPasswordInstructions: String? = nil,
                 skipXMLRPCCheckForSiteDiscovery: Bool = false,
                 skipXMLRPCCheckForSiteAddressLogin: Bool = false,
                 enableManualSiteCredentialLogin: Bool = false,
                 enableManualErrorHandlingForSiteCredentialLogin: Bool = false,
                 useEnterEmailAddressAsStepValueForGetStartedVC: Bool = false,
                 enableSiteAddressLoginOnlyInPrologue: Bool = false,
                 enableSiteCreationGuide: Bool = false,
                 disableAutofill: Bool = false
    ) {

        self.wpcomClientId = wpcomClientId
        self.wpcomSecret = wpcomSecret
        self.wpcomScheme = wpcomScheme
        self.wpcomTermsOfServiceURL = wpcomTermsOfServiceURL
        self.wpcomBaseURL = wpcomBaseURL
        self.wpcomAPIBaseURL = wpcomAPIBaseURL
        self.whatIsWPComURL = whatIsWPComURL
        self.googleLoginClientId = googleLoginClientId
        self.googleLoginServerClientId = googleLoginServerClientId
        self.googleLoginScheme = googleLoginScheme
        self.userAgent = userAgent
        self.showLoginOptions = showLoginOptions
        self.enableSignUp = enableSignUp
        self.enableSignInWithApple = enableSignInWithApple
        self.enableUnifiedAuth = enableUnifiedAuth
        self.enableUnifiedCarousel = enableUnifiedCarousel
        self.enablePasskeys = enablePasskeys
        self.displayHintButtons = displayHintButtons
        self.enableSignupWithGoogle = enableSignupWithGoogle
        self.continueWithSiteAddressFirst = continueWithSiteAddressFirst
        self.enableSiteCredentialsLoginForSelfHostedSites = enableSiteCredentialsLoginForSelfHostedSites
        self.isWPComLoginRequiredForSiteCredentialsLogin = isWPComLoginRequiredForSiteCredentialsLogin
        self.isWPComMagicLinkPreferredToPassword = isWPComMagicLinkPreferredToPassword
        self.isWPComMagicLinkShownAsSecondaryActionOnPasswordScreen = isWPComMagicLinkShownAsSecondaryActionOnPasswordScreen
        self.enableWPComLoginOnlyInPrologue = enableWPComLoginOnlyInPrologue
        self.enableSiteCreation = enableSiteCreation
        self.enableSocialLogin = enableSocialLogin
        self.emphasizeEmailForWPComPassword = emphasizeEmailForWPComPassword
        self.wpcomPasswordInstructions = wpcomPasswordInstructions
        self.skipXMLRPCCheckForSiteDiscovery = skipXMLRPCCheckForSiteDiscovery
        self.skipXMLRPCCheckForSiteAddressLogin = skipXMLRPCCheckForSiteAddressLogin
        self.enableManualSiteCredentialLogin = enableManualSiteCredentialLogin
        self.enableManualErrorHandlingForSiteCredentialLogin = enableManualErrorHandlingForSiteCredentialLogin
        self.useEnterEmailAddressAsStepValueForGetStartedVC = useEnterEmailAddressAsStepValueForGetStartedVC
        self.enableSiteAddressLoginOnlyInPrologue = enableSiteAddressLoginOnlyInPrologue
        self.enableSiteCreationGuide = enableSiteCreationGuide
        self.disableAutofill = disableAutofill
    }
}
