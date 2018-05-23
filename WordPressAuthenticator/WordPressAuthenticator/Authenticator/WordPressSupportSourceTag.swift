import Foundation


// MARK: - Authentication Flow Event. Useful to relay internal Auth events over to activity trackers.
//
public struct WordPressSupportSourceTag {
    public let name: String
    public let origin: String?
    
    public init(name: String, origin: String? = nil) {
        self.name = name
        self.origin = origin
    }
}

func ==(lhs: WordPressSupportSourceTag, rhs: WordPressSupportSourceTag) -> Bool {
    return lhs.name == rhs.name
}

extension WordPressSupportSourceTag {
    public static var generalLogin: WordPressSupportSourceTag {
        return WordPressSupportSourceTag(name: "generalLogin", origin: "origin:login-screen")
    }
    public static var jetpackLogin: WordPressSupportSourceTag {
        return WordPressSupportSourceTag(name: "jetpackLogin", origin: "origin:jetpack-login-screen")
    }
    public static var loginEmail: WordPressSupportSourceTag {
        return WordPressSupportSourceTag(name: "loginEmail", origin: "origin:login-email")
    }
    public static var login2FA: WordPressSupportSourceTag {
        return WordPressSupportSourceTag(name: "login2FA", origin: "origin:login-2fa")
    }
    public static var loginMagicLink: WordPressSupportSourceTag {
        return WordPressSupportSourceTag(name: "loginMagicLink", origin: "origin:login-magic-link")
    }
    public static var loginSiteAddress: WordPressSupportSourceTag {
        return WordPressSupportSourceTag(name: "loginSiteAddress", origin: "origin:login-site-address")
    }
    public static var loginUsernamePassword: WordPressSupportSourceTag {
        return WordPressSupportSourceTag(name: "loginUsernamePassword", origin: "origin:login-username-password")
    }
    public static var loginWPComPassword: WordPressSupportSourceTag {
        return WordPressSupportSourceTag(name: "loginWPComPassword", origin: "origin:login-wpcom-password")
    }
    public static var wpComSignupEmail: WordPressSupportSourceTag {
        return WordPressSupportSourceTag(name: "wpComSignupEmail", origin: "origin:wpcom-signup-email-entry")
    }
    public static var wpComSignup: WordPressSupportSourceTag {
        return WordPressSupportSourceTag(name: "wpComSignup", origin: "origin:signup-screen")
    }
    public static var wpComSignupWaitingForGoogle: WordPressSupportSourceTag {
        return WordPressSupportSourceTag(name: "wpComSignupWaitingForGoogle", origin: "origin:signup-waiting-for-google")
    }
    public static var wpComSignupMagicLink: WordPressSupportSourceTag {
        return WordPressSupportSourceTag(name: "wpComSignupMagicLink", origin: "origin:signup-magic-link")
    }
}
