import UIKit
import WordPressAuthenticator

protocol WordPressAuthenticatorProtocol {
    static func loginUI() -> UIViewController?
    static func track(_ event: WPAnalyticsStat)
}

extension WordPressAuthenticator: WordPressAuthenticatorProtocol {
    static func loginUI() -> UIViewController? {
        Self.loginUI(showCancel: false, restrictToWPCom: false, onLoginButtonTapped: nil)
    }
}
