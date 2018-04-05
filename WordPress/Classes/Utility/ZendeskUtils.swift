import Foundation
import ZendeskSDK

@objc class ZendeskUtils: NSObject {

    // MARK: - Properties

    static var sharedInstance: ZendeskUtils = ZendeskUtils()

    static var zendeskEnabled: Bool {
        return UserDefaults.standard.bool(forKey: UserDefaultsKeys.zendeskEnabled)
    }

    // MARK: - Public Methods

    @objc static func setup() {
        guard let appId = ApiCredentials.zendeskAppId(),
            let url = ApiCredentials.zendeskUrl(),
            let clientId = ApiCredentials.zendeskClientId(),
            appId.count > 0,
            url.count > 0,
            clientId.count > 0 else {
                ZendeskUtils.sharedInstance.enableZendesk(false)
                return
        }

        ZDKConfig.instance().initialize(withAppId: appId,
                                        zendeskUrl: url,
                                        clientId: clientId)

        ZendeskUtils.sharedInstance.enableZendesk(true)
    }

    static func showHelpCenterFrom(_ navController: UINavigationController) {
        let zendeskIdentity = ZDKAnonymousIdentity()
        ZDKConfig.instance().userIdentity = zendeskIdentity

        let helpCenterContentModel = ZDKHelpCenterOverviewContentModel.defaultContent()

        helpCenterContentModel?.groupType = .category
        helpCenterContentModel?.groupIds = [HelpCenterFilters.mobileCategoryID]
        helpCenterContentModel?.labels = [HelpCenterFilters.iosLabel]

        ZDKHelpCenter.pushOverview(navController, with: helpCenterContentModel)
    }

}

// MARK: - Private Extension

private extension ZendeskUtils {
    func enableZendesk(_ enabled: Bool) {
        let defaults = UserDefaults.standard
        defaults.set(enabled, forKey: UserDefaultsKeys.zendeskEnabled)
        defaults.synchronize()
        DDLogInfo("Zendesk Enabled: \(enabled)")
    }

    struct UserDefaultsKeys {
        static let zendeskEnabled = "wp_zendesk_enabled"
    }

    struct HelpCenterFilters {
        static let mobileCategoryID = "360000041586"
        static let iosLabel = "iOS"
    }

}
