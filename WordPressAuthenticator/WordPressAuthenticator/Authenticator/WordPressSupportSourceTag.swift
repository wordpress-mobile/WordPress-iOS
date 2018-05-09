import Foundation


// MARK: - Authentication Flow Event. Useful to relay internal Auth events over to activity trackers.
//
public struct WordPressSupportSourceTag: RawRepresentable {
    let name: String
    
    public init(rawValue: String) {
        name = rawValue
    }
    
    public var rawValue: String {
        return name
    }
}

extension WordPressSupportSourceTag {
    public static var generalLogin: WordPressSupportSourceTag {
        return WordPressSupportSourceTag(rawValue: "generalLogin")
    }
    public static var jetpackLogin: WordPressSupportSourceTag {
        return WordPressSupportSourceTag(rawValue: "jetpackLogin")
    }
    public static var loginEmail: WordPressSupportSourceTag {
        return WordPressSupportSourceTag(rawValue: "loginEmail")
    }
    public static var login2FA: WordPressSupportSourceTag {
        return WordPressSupportSourceTag(rawValue: "login2FA")
    }
    public static var loginMagicLink: WordPressSupportSourceTag {
        return WordPressSupportSourceTag(rawValue: "loginMagicLink")
    }
    public static var loginSiteAddress: WordPressSupportSourceTag {
        return WordPressSupportSourceTag(rawValue: "loginSiteAddress")
    }
    public static var loginUsernamePassword: WordPressSupportSourceTag {
        return WordPressSupportSourceTag(rawValue: "loginUsernamePassword")
    }
    public static var loginWPComPassword: WordPressSupportSourceTag {
        return WordPressSupportSourceTag(rawValue: "loginWPComPassword")
    }
    public static var wpComSignupEmail: WordPressSupportSourceTag {
        return WordPressSupportSourceTag(rawValue: "wpComSignupEmail")
    }
    public static var wpComSignup: WordPressSupportSourceTag {
        return WordPressSupportSourceTag(rawValue: "wpComSignup")
    }
    public static var wpComSignupWaitingForGoogle: WordPressSupportSourceTag {
        return WordPressSupportSourceTag(rawValue: "wpComSignupWaitingForGoogle")
    }
    public static var wpComSignupMagicLink: WordPressSupportSourceTag {
        return WordPressSupportSourceTag(rawValue: "wpComSignupMagicLink")
    }
}
