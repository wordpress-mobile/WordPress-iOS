import Foundation

/// This struct encapsulates the *remote* Jetpack settings available for a Blog entity
///
public struct RemoteBlogJetpackSettings {

    /// Indicates whether the Jetpack site's monitor is on or off
    ///
    public let monitorEnabled: Bool
    
    /// Indicates whether Jetpack will block malicious login attemps
    ///
    public let blockMaliciousLoginAttempts: Bool

    /// List of IP addresses that will never be blocked for logins by Jetpack
    ///
    public let loginWhiteListedIPAddresses: Set<String>

    /// Indicates whether WordPress.com SSO is enabled for the Jetpack site
    ///
    public let ssoEnabled: Bool

    /// Indicates whether SSO will try to match accounts by email address
    ///
    public let ssoMatchAccountsByEmail: Bool

    /// Indicates whether to force or not two-step authentication when users log in via WordPress.com
    ///
    public let ssoRequireTwoStepAuthentication: Bool

    public init(monitorEnabled: Bool,
                blockMaliciousLoginAttempts: Bool,
                loginWhiteListedIPAddresses: Set<String>,
                ssoEnabled: Bool,
                ssoMatchAccountsByEmail: Bool,
                ssoRequireTwoStepAuthentication: Bool) {
        self.monitorEnabled = monitorEnabled
        self.blockMaliciousLoginAttempts = blockMaliciousLoginAttempts
        self.loginWhiteListedIPAddresses = loginWhiteListedIPAddresses
        self.ssoEnabled = ssoEnabled
        self.ssoMatchAccountsByEmail = ssoMatchAccountsByEmail
        self.ssoRequireTwoStepAuthentication = ssoRequireTwoStepAuthentication
    }
}
