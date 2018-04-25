import Foundation
import ZendeskSDK
import CoreTelephony

@objc class ZendeskUtils: NSObject {

    // MARK: - Properties

    static var sharedInstance: ZendeskUtils = ZendeskUtils()

    static var zendeskEnabled: Bool = false

    private static var identityCreated = false

    private static var appVersion: String {
        return Bundle.main.shortVersionString() ?? Constants.unknownValue
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

    static func showHelpCenter(from controller: UIViewController) {

        if !ZendeskUtils.identityCreated {
            return
        }

        guard let helpCenterContentModel = ZDKHelpCenterOverviewContentModel.defaultContent() else {
            return
        }

        helpCenterContentModel.groupType = .category
        helpCenterContentModel.groupIds = [Constants.mobileCategoryID]
        helpCenterContentModel.labels = [Constants.articleLabel]

        let presentInController = ZendeskUtils.sharedInstance.configureViewController(controller)
        ZDKHelpCenter.presentOverview(presentInController, with: helpCenterContentModel)
    }

    static func showNewRequest(from controller: UIViewController) {

        if !ZendeskUtils.identityCreated {
            return
        }

        let presentInController = ZendeskUtils.sharedInstance.configureViewController(controller)
        ZDKRequests.presentRequestCreation(with: presentInController)
    }

    static func showTicketList(from controller: UIViewController) {

        if !ZendeskUtils.identityCreated {
            return
        }

        let presentInController = ZendeskUtils.sharedInstance.configureViewController(controller)
        ZDKRequests.presentRequestList(with: presentInController)
    }

    static func createRequest() {

        if !ZendeskUtils.identityCreated {
            return
        }

        ZDKRequests.configure { (account, requestCreationConfig) in

            guard let requestCreationConfig = requestCreationConfig else {
                return
            }

            // Set Zendesk ticket form to use
            ZDKConfig.instance().ticketFormId = TicketFieldIDs.form as NSNumber

            // Set form field values
            let zdUtilsInstance = ZendeskUtils.sharedInstance
            var ticketFields = [ZDKCustomField]()
            ticketFields.append(ZDKCustomField(fieldId: TicketFieldIDs.appVersion as NSNumber, andValue: ZendeskUtils.appVersion))
            ticketFields.append(ZDKCustomField(fieldId: TicketFieldIDs.allBlogs as NSNumber, andValue: zdUtilsInstance.getBlogInformation()))
            ticketFields.append(ZDKCustomField(fieldId: TicketFieldIDs.deviceFreeSpace as NSNumber, andValue: zdUtilsInstance.getDeviceFreeSpace()))
            ticketFields.append(ZDKCustomField(fieldId: TicketFieldIDs.networkInformation as NSNumber, andValue: zdUtilsInstance.getNetworkInformation()))
            ticketFields.append(ZDKCustomField(fieldId: TicketFieldIDs.logs as NSNumber, andValue: zdUtilsInstance.getLogFile()))
            ZDKConfig.instance().customTicketFields = ticketFields

            // Set tags
            requestCreationConfig.tags = zdUtilsInstance.getTags()

            // Set the ticket subject
            requestCreationConfig.subject = Constants.ticketSubject
        }
    }

}

// MARK: - Private Extension

private extension ZendeskUtils {

    func enableZendesk(_ enabled: Bool) {
        ZendeskUtils.zendeskEnabled = enabled
        DDLogInfo("Zendesk Enabled: \(enabled)")
    }

    func configureViewController(_ controller: UIViewController) -> UIViewController {
        // If the controller is a UIViewController, set the modal display for iPad.
        // If the controller is a UINavigationController, do nothing as the ZD views will inherit from that.
        if !controller.isKind(of: UINavigationController.self) && WPDeviceIdentification.isiPad() {
            controller.modalPresentationStyle = .formSheet
            controller.modalTransitionStyle = .crossDissolve
        }
        return controller
    }

    // MARK: - Data Helpers

    func getDeviceFreeSpace() -> String {

        guard let resourceValues = try? URL(fileURLWithPath: "/").resourceValues(forKeys: [.volumeAvailableCapacityKey]),
            let capacity = resourceValues.volumeAvailableCapacity else {
                return Constants.unknownValue
        }

        // format string using human readable units. ex: 1.5 GB
        return ByteCountFormatter.string(fromByteCount: Int64(capacity), countStyle: .binary)
    }

    func getLogFile() -> String {

        guard let appDelegate = UIApplication.shared.delegate as? WordPressAppDelegate,
            let fileLogger = appDelegate.logger.fileLogger,
            let logFileInformation = fileLogger.logFileManager.sortedLogFileInfos.first,
            let logData = try? Data(contentsOf: URL(fileURLWithPath: logFileInformation.filePath)),
            let logText = String.init(data: logData, encoding: .utf8) else {
            return ""
        }

        return logText
    }

    func getBlogInformation() -> String {

        let blogService = BlogService(managedObjectContext: ContextManager.sharedInstance().mainContext)

        guard let allBlogs = blogService.blogsForAllAccounts() as? [Blog], allBlogs.count > 0 else {
            return Constants.noValue
        }

        return (allBlogs.map { $0.logDescription() }).joined(separator: Constants.blogSeperator)
    }

    func getTags() -> [String] {

        var tags = [String]()

        let context = ContextManager.sharedInstance().mainContext
        let accountService = AccountService.init(managedObjectContext: context)

        if let defaultAccount = accountService.defaultWordPressComAccount() {

            tags = defaultAccount.blogs.filter {
                $0.planTitle != nil
                }.map {
                    $0.planTitle!
                }.unique

            tags.append(Constants.wpComTag)

        } else {
            tags.append(Constants.jetpackTag)
        }

        return tags
    }

    func getNetworkInformation() -> String {

        var networkInformation = [String]()

        let reachibilityStatus = ZDKReachability.forInternetConnection().currentReachabilityStatus()

        let networkType: String = {
            switch reachibilityStatus {
            case .reachableViaWiFi:
                return Constants.networkWiFi
            case .reachableViaWWAN:
                return Constants.networkWWAN
            default:
                return Constants.unknownValue
            }
        }()

        let networkCarrier = CTTelephonyNetworkInfo().subscriberCellularProvider
        let carrierName = networkCarrier?.carrierName ?? Constants.unknownValue
        let carrierCountryCode = networkCarrier?.isoCountryCode ?? Constants.unknownValue

        networkInformation.append("\(Constants.networkTypeLabel) \(networkType)")
        networkInformation.append("\(Constants.networkCarrierLabel) \(carrierName)")
        networkInformation.append("\(Constants.networkCountryCodeLabel) \(carrierCountryCode)")

        return networkInformation.joined(separator: "\n")
    }

    // MARK: - Contants

    struct Constants {
        static let unknownValue = "unknown"
        static let noValue = "none"
        static let mobileCategoryID = "360000041586"
        static let articleLabel = "iOS"
        static let ticketSubject = NSLocalizedString("WordPress for iOS Support", comment: "Subject of new Zendesk ticket.")
        static let blogSeperator = "\n----------\n"
        static let jetpackTag = "jetpack"
        static let wpComTag = "wpcom"
        static let networkWiFi = "WiFi"
        static let networkWWAN = "Mobile"
        static let networkTypeLabel = "Network Type:"
        static let networkCarrierLabel = "Carrier:"
        static let networkCountryCodeLabel = "Country Code:"
    }

    struct TicketFieldIDs {
        static let form: UInt64 = 360000010286
        static let appVersion: UInt64 = 360000086866
        static let allBlogs: UInt64 = 360000087183
        static let deviceFreeSpace: UInt64 = 360000089123
        static let networkInformation: UInt64 = 360000086966
        static let logs: UInt64 = 22871957
    }

}
