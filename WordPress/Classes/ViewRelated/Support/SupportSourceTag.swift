import Foundation

/// Identifies the screen a support request originates from, so support tickets
/// can be tagged with their source. App-owned replacement for the
/// WordPressAuthenticator library's `WordPressSupportSourceTag`.
struct SupportSourceTag {
    let name: String
    let origin: String?

    init(name: String, origin: String? = nil) {
        self.name = name
        self.origin = origin
    }
}

extension SupportSourceTag {
    static var wpComCreateSiteCreation: SupportSourceTag {
        SupportSourceTag(name: "wpComCreateSiteCreation", origin: "origin:wpcom-create-site-creation")
    }
    static var wpComCreateSiteDomain: SupportSourceTag {
        SupportSourceTag(name: "wpComCreateSiteDomain", origin: "origin:wpcom-create-site-domain")
    }
    static var wpComCreateSiteDetails: SupportSourceTag {
        SupportSourceTag(name: "wpComCreateSiteDetails", origin: "origin:wpcom-create-site-details")
    }
    static var wpComCreateSiteUsername: SupportSourceTag {
        SupportSourceTag(name: "wpComCreateSiteUsername", origin: "origin:wpcom-create-site-username")
    }
    static var wpComCreateSiteTheme: SupportSourceTag {
        SupportSourceTag(name: "wpComCreateSiteTheme", origin: "origin:wpcom-create-site-theme")
    }
    static var wpComCreateSiteCategory: SupportSourceTag {
        SupportSourceTag(name: "wpComCreateSiteCategory", origin: "origin:wpcom-create-site-category")
    }
    static var inAppFeedback: SupportSourceTag {
        SupportSourceTag(name: "inAppFeedback", origin: "origin:in-app-feedback")
    }
    static var deleteSite: SupportSourceTag {
        SupportSourceTag(name: "deleteSite", origin: "origin:delete-site")
    }
    static var closeAccount: SupportSourceTag {
        SupportSourceTag(name: "closeAccount", origin: "origin:close-account")
    }
    static var editorHelp: SupportSourceTag {
        SupportSourceTag(name: "editorHelp", origin: "origin:editor-help")
    }
}
