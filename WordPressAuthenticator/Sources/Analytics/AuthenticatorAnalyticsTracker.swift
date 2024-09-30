import Foundation
import WordPressShared

/// Implements the analytics tracking logic for our sign in flow.
///
public class AuthenticatorAnalyticsTracker {

    private static let defaultSource: Source = .default
    private static let defaultFlow: Flow = .prologue
    private static let defaultStep: Step = .prologue

    /// The method used for analytics tracking.  Useful for overriding in automated tests.
    ///
    typealias TrackerMethod = (_ event: AnalyticsEvent) -> Void

    public enum EventType: String {
        case step = "unified_login_step"
        case interaction = "unified_login_interaction"
        case failure = "unified_login_failure"
    }

    public enum Property: String {
        case failure
        case flow
        case click
        case source
        case step
    }

    public enum Source: String {
        /// Starts when the user logs in / sign up from the prologue screen
        ///
        case `default`

        case jetpack
        case share
        case deeplink
        case reauthentication

        /// Starts when the used adds a site from the site picker
        ///
        case selfHosted = "self_hosted"
    }

    public enum Flow: String {
        /// The initial flow before we decide whether the user is logging in or signing up
        ///
        case wpCom = "wordpress_com"

        /// Flow for Google login
        ///
        case loginWithGoogle = "google_login"

        /// Flow for Google  signup
        ///
        case signupWithGoogle = "google_signup"

        /// Flow for Apple login
        ///
        case loginWithApple = "siwa_login"

        /// Flow for Apple signup
        ///
        case signupWithApple = "siwa_signup"

        /// Flow for iCloud Keychain login
        ///
        case loginWithiCloudKeychain = "icloud_keychain_login"

        /// The flow that starts when we offer the user the magic link login
        ///
        case loginWithMagicLink = "login_magic_link"

        /// This flow starts when the user decides to login with a password instead
        ///
        case loginWithPassword = "login_password"

        /// This flow starts when the user decides to login with a password instead, with magic link logic emphasis
        /// where the CTA is a secondary CTA instead of a table view row
        ///
        case loginWithPasswordWithMagicLinkEmphasis = "login_password_magic_link_emphasis"

        /// This flow starts when the user decides to log in with their site address
        ///
        case loginWithSiteAddress = "login_site_address"

        /// This flow starts when the user wants to troubleshoot their site by inputting its address
        ///
        case siteDiscovery = "site_discovery"

        /// This flow represents the signup (when the user inputs an email that’s not registered with a .com account)
        ///
        case signup

        /// This flow represents the prologue screen.
        ///
        case prologue
    }

    public enum Step: String {
        /// Gets shown on the Prologue screen
        ///
        case prologue

        /// Triggered when a flow is started
        ///
        case start

        /// Triggered when a user requests a magic link and sees the screen with the “Open mail” button
        ///
        case magicLinkRequested = "magic_link_requested"

        /// This represents the user opening their mail. It’s not strictly speaking an in-app screen but for the user it is part of the flow.
        case emailOpened = "email_opened"

        /// Represents the screen or step in which WPCOM account email is entered by the user
        ///
        case enterEmailAddress = "enter_email_address"

        /// The screen with a username and password visible
        ///
        case usernamePassword = "username_password"

        /// The screen that requests the password
        ///
        case passwordChallenge = "password_challenge"

        /// Triggered on the epilogue screen
        ///
        case success

        /// Triggered on the help screen
        ///
        case help

        /// When we ask user to input the code from the 2 factor authentication
        case twoFactorAuthentication = "2fa"

        /// Triggered when a user enters site credentials and sees the screen with instructions to verify email. (`VerifyEmailViewController`)
        ///
        case verifyEmailInstructions = "instructions_to_verify_email"

        /// Triggered when a magic link is automatically requested after filling in email address and the requested screen is shown
        ///
        case magicLinkAutoRequested = "magic_link_auto_requested"
    }

    public enum ClickTarget: String {
        /// Tracked when submitting the email form, the email & password form, site address form,
        /// username & password form and signup email form
        ///
        case submit

        /// Tracked when the user clicks on continue in the login/signup epilogue
        ///
        case `continue`

        /// Tracked when the post signup interstitial screen is dismissed, when the
        /// login signup help dialog is dismissed and when the email hint dialog is dismissed
        ///
        case dismiss

        /// Tracked when the user clicks “Continue with WordPress.com” on the Prologue screen
        ///
        case continueWithWordPressCom = "continue_with_wordpress_com"

        /// Tracked when the user clicks “What is WordPress.com?" button on the WordPress.com flow screen
        ///
        case whatIsWPCom = "what_is_wordpress_com"

        /// Tracked when the user clicks “Login with site address” on the Prologue screen
        ///
        case loginWithSiteAddress = "login_with_site_address"

        /// When the user tries to login with Apple from the confirmation screen
        ///
        case loginWithApple = "login_with_apple"

        /// Tracked when the user clicks “Login with Google” on the WordPress.com flow screen
        ///
        case loginWithGoogle = "login_with_google"

        /// When the user clicks on “Forgotten password” on one of the screens that show the password field
        ///
        case forgottenPassword = "forgotten_password"

        /// When the user clicks on terms of service anywhere
        ///
        case termsOfService = "terms_of_service_clicked"

        /// When the user tries to sign up with email from the confirmation screen
        ///
        case signupWithEmail = "signup_with_email"

        /// When the user tries to sign up with Apple from the confirmation screen
        ///
        case signupWithApple = "signup_with_apple"

        /// When the user tries to sign up with Google from the confirmation screen
        ///
        case signupWithGoogle = "signup_with_google"

        /// When the user opens the email client from the magic link screen
        ///
        case openEmailClient = "open_email_client"

        /// Any time the user clicks on the help icon in the login flow
        ///
        case showHelp = "show_help"

        /// Used on the 2FA screen to send code with a text instead of using the authenticator app
        ///
        case sendCodeWithText = "send_code_with_text"

        /// Used on the 2FA screen to use a security key  instead of using the authenticator app
        ///
        case enterSecurityKey = "enter_security_key"

        /// Used on the 2FA screen to submit authentication code
        ///
        case submitTwoFactorCode = "submit_2fa_code"

        /// When the user requests a magic link after filling in email address
        ///
        case requestMagicLink = "request_magic_link"

        /// Click on “Create new site” button after a successful signup
        ///
        case createNewSite = "create_new_site"

        /// Adding a self-hosted site from the epilogue
        ///
        case addSelfHostedSite = "add_self_hosted_site"

        /// Connecting a site from the epilogue
        ///
        case connectSite = "connect_site"

        /// Picking an avatar from the epilogue after a successful signup
        ///
        case selectAvatar = "select_avatar"

        /// Editing the username from the epilogue after a successful signup
        ///
        case editUsername = "edit_username"

        /// Clicking on “Need help finding site address” from a dialog
        ///
        case helpFindingSiteAddress = "help_finding_site_address"

        /// When the user clicks on the email field to log in, this triggers the hint dialog to show up
        ///
        case selectEmailField = "select_email_field"

        /// When the user selects an email from the hint dialog
        ///
        case pickEmailFromHint = "pick_email_from_hint"

        /// When the user clicks on “Create account” on the signup confirmation screen
        ///
        case createAccount = "create_account"

        /// When the user taps of "Sign in with site credentials" button in `GetStartedViewController`
        ///
        case signInWithSiteCredentials = "sign_in_with_site_credentials"

        /// When the user clicks on “Login with account password” on `VerifyEmailViewController`
        ///
        case loginWithAccountPassword = "login_with_password"
    }

    public enum Failure: String {
        /// Failure to guess XMLRPC URL
        ///
        case loginFailedToGuessXMLRPC = "login_failed_to_guess_xmlrpc_url"
    }

    /// Shared Instance.
    ///
    public static var shared: AuthenticatorAnalyticsTracker = {
        return AuthenticatorAnalyticsTracker()
    }()

    /// State for the analytics tracker.
    ///
    public class State {
        internal(set) public var lastFlow: Flow
        internal(set) public var lastSource: Source
        internal(set) public var lastStep: Step

        init(lastFlow: Flow = AuthenticatorAnalyticsTracker.defaultFlow, lastSource: Source = AuthenticatorAnalyticsTracker.defaultSource, lastStep: Step = AuthenticatorAnalyticsTracker.defaultStep) {
            self.lastFlow = lastFlow
            self.lastSource = lastSource
            self.lastStep = lastStep
        }
    }

    /// The state of this tracker.
    ///
    public let state = State()

    /// The backing analytics tracking method.  Can be overridden for testing purposes.
    ///
    let track: TrackerMethod

    /// Whether tracking is enabled or not.  This is just a convenience configuration to enable this tracker to be turned on and off
    /// using a feature flag.  It should go away once we remove the legacy tracking.
    ///
    let enabled: Bool

    // MARK: - Initializers

    init(enabled: Bool = WordPressAuthenticator.shared.configuration.enableUnifiedAuth, track: @escaping TrackerMethod = WPAnalytics.track) {
        self.enabled = enabled
        self.track = track
    }

    /// Resets the flow and step to the defaults.  The source is left untouched, and should only be set explicitely.
    ///
    func resetState() {
        set(flow: Self.defaultFlow)
        set(step: Self.defaultStep)
    }

    // MARK: - Legacy vs Unified tracking

    /// This method will reply whether, for the current flow in the state, tracking is enabled.
    ///
    /// It's the responsibility of the class calling the tracking methods to check this before attempting to actually do the tracking.
    ///
    /// - Returns: `true` if we can track using the state machine.
    ///
    public func canTrack() -> Bool {
        return enabled
    }

    /// This is a convenience method, that's useful for cases where we simply want to check if the legacy tracking should be
    /// enabled.  It can be particularly useful in cases where we don't have a matching tracking call in the new flow.
    ///
    ///  - Returns: `true` if we must use legacy tracking, `false` otherwise.
    ///
    public func shouldUseLegacyTracker() -> Bool {
        return !canTrack()
    }

    // MARK: - Tracking

    /// Track a step within a flow.
    ///
    public func track(step: Step) {
        guard canTrack() else {
            return
        }

        track(event(step: step))
    }

    /// Track a click interaction.
    ///
    public func track(click: ClickTarget) {
        guard canTrack() else {
            return
        }

        track(event(click: click))
    }

    /// Track a predefined failure enum.
    ///
    public func track(failure: Failure) {
        track(failure: failure.rawValue)
    }

    /// Track a failure.
    ///
    public func track(failure: String) {
        guard canTrack() else {
            return
        }

        track(event(failure: failure))
    }

    // MARK: - Tracking: Legacy Tracking Support

    /// Tracks a step within a flow if tracking is enabled for that flow, or executes the specified block if tracking is not enabled
    /// for the flow.
    ///
    public func track(step: Step, ifTrackingNotEnabled legacyTracking: () -> Void) {
        guard canTrack() else {
            legacyTracking()
            return
        }

        track(step: step)
    }

    /// Track a click interaction if tracking is enabled for that flow, or executes the specified block if tracking is not enabled
    /// for the flow.
    ///
    public func track(click: ClickTarget, ifTrackingNotEnabled legacyTracking: () -> Void) {
        guard canTrack() else {
            legacyTracking()
            return
        }

        track(event(click: click))
    }

    /// Track a failure if tracking is enabled for that flow, or executes the specified block if tracking is not enabled
    /// for the flow.
    ///
    public func track(failure: String, ifTrackingNotEnabled legacyTracking: () -> Void) {
        guard canTrack() else {
            legacyTracking()
            return
        }

        track(event(failure: failure))
    }

    // MARK: - Event Construction & Context Updating

    /// Creates an event for a step.  Updates the state machine.
    ///
    /// - Parameters:
    ///     - step: the step we're tracking.
    ///     - flow: the flow that the step belongs to.
    ///
    /// - Returns: an analytics event representing the step.
    ///
    private func event(step: Step) -> AnalyticsEvent {
        let event = AnalyticsEvent(
            name: EventType.step.rawValue,
            properties: properties(step: step))

        state.lastStep = step

        return event
    }

    /// Creates an event for a failure.  Loads the properties from the state machine.
    ///
    /// - Parameters:
    ///     - failure: the error message we want to track.
    ///
    /// - Returns: an analytics event representing the failure.
    ///
    private func event(failure: String) -> AnalyticsEvent {
        var properties = lastProperties()
        properties[Property.failure.rawValue] = failure

        return AnalyticsEvent(
            name: EventType.failure.rawValue,
            properties: properties)
    }

    /// Creates an event for a click interaction.  Loads the properties from the state machine.
    ///
    /// - Parameters:
    ///     - click: the target of the click interaction.
    ///
    /// - Returns: an analytics event representing the click interaction.
    ///
    private func event(click: ClickTarget) -> AnalyticsEvent {
        var properties = lastProperties()
        properties[Property.click.rawValue] = click.rawValue

        return AnalyticsEvent(
            name: EventType.interaction.rawValue,
            properties: properties)
    }

    // MARK: - Source & Flow

    /// Allows the caller to set the flow without tracking.
    ///
    public func set(flow: Flow) {
        state.lastFlow = flow
    }

    /// Allows the caller to set the source without tracking.
    ///
    public func set(source: Source) {
        state.lastSource = source
    }

    /// Allows the caller to set the step without tracking.
    ///
    public func set(step: Step) {
        state.lastStep = step
    }

    // MARK: - Properties

    private func properties(step: Step) -> [String: String] {
        return properties(step: step, flow: state.lastFlow, source: state.lastSource)
    }

    private func properties(step: Step, flow: Flow, source: Source) -> [String: String] {
        return [
            Property.flow.rawValue: flow.rawValue,
            Property.source.rawValue: source.rawValue,
            Property.step.rawValue: step.rawValue
        ]
    }

    /// Retrieve the last step, flow and source stored in the state machine.
    ///
    private func lastProperties() -> [String: String] {
        return properties(step: state.lastStep, flow: state.lastFlow, source: state.lastSource)
    }
}
