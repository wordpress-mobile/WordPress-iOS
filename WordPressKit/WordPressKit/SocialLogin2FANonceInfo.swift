import Foundation

@objc
public class SocialLogin2FANonceInfo: NSObject {
    var nonceSMS = ""
    var nonceBackup = ""
    var nonceAuthenticator = ""
    var supportedAuthTypes = [String]() // backup|authenticator|sms
    var notificationSent = "" // none|sms
    var phoneNumber = "" // The last two digits of the phone number to which an SMS was sent.

    private enum Constants {
        static let lastUsedPlaceholder = "last_used_placeholder"
    }

    /// These constants match the server-side authentication code
    private enum AuthTypeLengths {
        static let authenticator = 6
        static let sms = 7
        static let backup = 8
    }

    public func authTypeAndNonce(for code: String) -> (String, String) {
        let typeNoncePair: (String, String)
        switch code.count {
        case AuthTypeLengths.sms:
            typeNoncePair = ("sms", nonceSMS)
            nonceSMS = Constants.lastUsedPlaceholder
        case AuthTypeLengths.backup:
            typeNoncePair = ("backup", nonceBackup)
            nonceBackup = Constants.lastUsedPlaceholder
        case AuthTypeLengths.authenticator:
            fallthrough
        default:
            typeNoncePair = ("authenticator", nonceAuthenticator)
            nonceAuthenticator = Constants.lastUsedPlaceholder
        }
        return typeNoncePair
    }

    public func updateNonce(with newNonce: String) {
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
