import Foundation
import WordPressAuthenticator


// MARK: - WordPressSupportSourceTag ClientApp Helper Methods
//
extension WordPressSupportSourceTag {

    /// Returns the matching SupportSourceTag enum case, matching for the current WordPressSupportSourceTag (Auth Framework) enum case.
    ///
    func toSupportSourceTag() -> SupportSourceTag {
        return SupportSourceTag(rawValue: rawValue)
    }
}


/// WordPress-Specific SupportSourceTag(s). (Extensible Enum Technique!)
///
extension WordPressSupportSourceTag {
    public static var wpComCreateSiteCreation: WordPressSupportSourceTag {
        return WordPressSupportSourceTag(rawValue: "wpComCreateSiteCreation")
    }
    public static var wpComCreateSiteDomain: WordPressSupportSourceTag {
        return WordPressSupportSourceTag(rawValue: "wpComCreateSiteDomain")
    }
    public static var wpComCreateSiteDetails: WordPressSupportSourceTag {
        return WordPressSupportSourceTag(rawValue: "wpComCreateSiteDetails")
    }
    public static var wpComCreateSiteUsername: WordPressSupportSourceTag {
        return WordPressSupportSourceTag(rawValue: "wpComCreateSiteUsername")
    }
    public static var wpComCreateSiteTheme: WordPressSupportSourceTag {
        return WordPressSupportSourceTag(rawValue: "wpComCreateSiteTheme")
    }
    public static var wpComCreateSiteCategory: WordPressSupportSourceTag {
        return WordPressSupportSourceTag(rawValue: "wpComCreateSiteCategory")
    }
    public static var inAppFeedback: WordPressSupportSourceTag {
        return WordPressSupportSourceTag(rawValue: "inAppFeedback")
    }
}
