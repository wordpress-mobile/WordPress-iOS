import Foundation

@objc
public class SocialLogin2FANonceInfo: NSObject {
    @objc public var nonceSMS = ""
    @objc var nonceBackup = ""
    @objc var nonceAuthenticator = ""
    @objc var supportedAuthTypes = [String]() // backup|authenticator|sms
    @objc var notificationSent = "" // none|sms
    @objc var phoneNumber = "" // The last two digits of the phone number to which an SMS was sent.

    private enum Constants {
        static let lastUsedPlaceholder = "last_used_placeholder"
    }

    /// These constants match the server-side authentication code
    public enum TwoFactorTypeLengths: Int {
        case authenticator = 6
        case sms = 7
        case backup = 8
    }

    public func authTypeAndNonce(for code: String) -> (String, String) {
        let typeNoncePair: (String, String)
        switch code.count {
        case TwoFactorTypeLengths.sms.rawValue:
            typeNoncePair = ("sms", nonceSMS)
            nonceSMS = Constants.lastUsedPlaceholder
        case TwoFactorTypeLengths.backup.rawValue:
            typeNoncePair = ("backup", nonceBackup)
            nonceBackup = Constants.lastUsedPlaceholder
        case TwoFactorTypeLengths.authenticator.rawValue:
            fallthrough
        default:
            typeNoncePair = ("authenticator", nonceAuthenticator)
            nonceAuthenticator = Constants.lastUsedPlaceholder
        }
        return typeNoncePair
    }

    @objc public func updateNonce(with newNonce: String) {
        switch Constants.lastUsedPlaceholder {
        case nonceSMS:
            nonceSMS = newNonce
        case nonceBackup:
            nonceBackup = newNonce
        case nonceAuthenticator:
            fallthrough
        default:
            nonceAuthenticator = newNonce
        }
    }
}
