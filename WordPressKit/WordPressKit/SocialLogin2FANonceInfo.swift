import Foundation

@objc
public class SocialLogin2FANonceInfo: NSObject {
    var nonceSMS = ""
    var nonceBackup = ""
    var nonceAuthenticator = ""
    var supportedAuthTypes = [String]() // backup|authenticator|sms
    var notificationSent = "" // none|sms
    var phoneNumber = "" // The last two digits of the phone number to which an SMS was sent.
}
