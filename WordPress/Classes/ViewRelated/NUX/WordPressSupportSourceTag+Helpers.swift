import Foundation
import WordPressAuthenticator

/// WordPress-Specific SupportSourceTag(s). (Extensible Enum Technique!)
///
extension WordPressSupportSourceTag {
    public static var wpComCreateSiteCreation: WordPressSupportSourceTag {
        return WordPressSupportSourceTag(name: "wpComCreateSiteCreation", origin: "origin:wpcom-create-site-creation")
    }
    public static var wpComCreateSiteDomain: WordPressSupportSourceTag {
        return WordPressSupportSourceTag(name: "wpComCreateSiteDomain", origin: "origin:wpcom-create-site-domain")
    }
    public static var wpComCreateSiteDetails: WordPressSupportSourceTag {
        return WordPressSupportSourceTag(name: "wpComCreateSiteDetails", origin: "origin:wpcom-create-site-details")
    }
    public static var wpComCreateSiteUsername: WordPressSupportSourceTag {
        return WordPressSupportSourceTag(name: "wpComCreateSiteUsername", origin: "origin:wpcom-create-site-username")
    }
    public static var wpComCreateSiteTheme: WordPressSupportSourceTag {
        return WordPressSupportSourceTag(name: "wpComCreateSiteTheme", origin: "origin:wpcom-create-site-theme")
    }
    public static var wpComCreateSiteCategory: WordPressSupportSourceTag {
        return WordPressSupportSourceTag(name: "wpComCreateSiteCategory", origin: "origin:wpcom-create-site-category")
    }
    public static var inAppFeedback: WordPressSupportSourceTag {
        return WordPressSupportSourceTag(name: "inAppFeedback", origin: "origin:in-app-feedback")
    }
    public static var deleteSite: WordPressSupportSourceTag {
        return WordPressSupportSourceTag(name: "deleteSite", origin: "origin:delete-site")
    }
}
