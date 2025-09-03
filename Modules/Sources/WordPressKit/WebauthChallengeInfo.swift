import Foundation

/// Type that represents the Webauthn challenge info return by Wordpress.com
///
@objc public class WebauthnChallengeInfo: NSObject {
    /// Challenge to be signed.
    ///
    @objc public var challenge = ""

    /// The website this request is for
    ///
    @objc public var rpID = ""

    /// Nonce required by Wordpress.com to verify the signed challenge
    ///
    @objc public var twoStepNonce = ""

    /// Allowed credential IDs.
    ///
    @objc public var allowedCredentialIDs: [String] = []

    init(challenge: String, rpID: String, twoStepNonce: String, allowedCredentialIDs: [String]) {
        self.challenge = challenge
        self.rpID = rpID
        self.twoStepNonce = twoStepNonce
        self.allowedCredentialIDs = allowedCredentialIDs
    }
}
