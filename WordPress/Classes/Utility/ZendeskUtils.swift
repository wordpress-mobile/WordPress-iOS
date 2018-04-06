import Foundation
import ZendeskSDK

/// A public struct for providing user specific information used to create Zendesk ticket.
///
struct ZendeskTicketFields {
    var appVersion: String
    var allBlogs: String
    var deviceFreeSpace: String
    var networkInformation: String
    var logs: String
    var tags: [String]
    
}

@objc class ZendeskUtils: NSObject {

    // MARK: - Properties

    static var sharedInstance: ZendeskUtils = ZendeskUtils()

    static var zendeskEnabled: Bool {
        return UserDefaults.standard.bool(forKey: Constants.zendeskEnabledUDKey)
    }

    private static var identityCreated = false

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

    static func createIdentity(with accountSettings: AccountSettings) {
        let zendeskIdentity = ZDKAnonymousIdentity()

        var userName = accountSettings.username
        if accountSettings.firstName.count > 0 || accountSettings.lastName.count > 0 {
            userName = (accountSettings.firstName + " " + accountSettings.lastName).trim()
        }

        zendeskIdentity.email = accountSettings.email
        zendeskIdentity.name = userName
        ZDKConfig.instance().userIdentity = zendeskIdentity
        ZendeskUtils.identityCreated = true
    }

    static func showHelpCenter(from navController: UINavigationController) {

        if !ZendeskUtils.identityCreated {
            return
        }

        guard let helpCenterContentModel = ZDKHelpCenterOverviewContentModel.defaultContent() else {
            return
        }

        helpCenterContentModel.groupType = .category
        helpCenterContentModel.groupIds = [Constants.mobileCategoryID]
        helpCenterContentModel.labels = [Constants.articleLabel]

        ZDKHelpCenter.pushOverview(navController, with: helpCenterContentModel)
    }

    static func showNewRequest(from navController: UINavigationController) {

        if !ZendeskUtils.identityCreated {
            return
        }

        ZDKRequests.presentRequestCreation(with: navController)
    }

    static func showTicketList(from navController: UINavigationController) {

        if !ZendeskUtils.identityCreated {
            return
        }

        ZDKRequests.pushRequestList(with: navController, layoutGuide: ZDKLayoutRespectTop)
    }

    static func createRequest(ticketInformation: ZendeskTicketFields) {

        if !ZendeskUtils.identityCreated {
            return
        }

        ZDKRequests.configure { (account, requestCreationConfig) in

            guard let requestCreationConfig = requestCreationConfig else {
                return
            }

            // Set Zendesk ticket form to use
            ZDKConfig.instance().ticketFormId = TicketFieldIDs.form

            // Set form field values
            var ticketFields = [ZDKCustomField]()
            ticketFields.append(ZDKCustomField(fieldId: TicketFieldIDs.appVersion, andValue: ticketInformation.appVersion))
            ticketFields.append(ZDKCustomField(fieldId: TicketFieldIDs.allBlogs, andValue: ticketInformation.allBlogs))
            ticketFields.append(ZDKCustomField(fieldId: TicketFieldIDs.deviceFreeSpace, andValue: ticketInformation.deviceFreeSpace))
            ticketFields.append(ZDKCustomField(fieldId: TicketFieldIDs.networkInformation, andValue: ticketInformation.networkInformation))
            ticketFields.append(ZDKCustomField(fieldId: TicketFieldIDs.logs, andValue: ticketInformation.logs))
            ZDKConfig.instance().customTicketFields = ticketFields

            // Set tags
            requestCreationConfig.tags = ticketInformation.tags

            // Set the ticket subject
            requestCreationConfig.subject = Constants.ticketSubject
        }
    }

}

// MARK: - Private Extension

private extension ZendeskUtils {

    func enableZendesk(_ enabled: Bool) {
        let defaults = UserDefaults.standard
        defaults.set(enabled, forKey: Constants.zendeskEnabledUDKey)
        defaults.synchronize()
        DDLogInfo("Zendesk Enabled: \(enabled)")
    }

    struct Constants {
        static let zendeskEnabledUDKey = "wp_zendesk_enabled"
        static let mobileCategoryID = "360000041586"
        static let articleLabel = "iOS"
        static let ticketSubject = NSLocalizedString("WordPress for iOS Support", comment: "Subject of new Zendesk ticket.")
    }

    struct TicketFieldIDs {
        static let form: NSNumber = 360000010286
        static let appVersion: NSNumber = 360000086866
        static let allBlogs: NSNumber = 360000087183
        static let deviceFreeSpace: NSNumber = 360000089123
        static let networkInformation: NSNumber = 360000086966
        static let logs: NSNumber = 22871957
    }

}
