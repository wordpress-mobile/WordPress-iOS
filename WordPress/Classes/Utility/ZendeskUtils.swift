import Foundation
import ZendeskSDK
import CoreTelephony

@objc class ZendeskUtils: NSObject {

    // MARK: - Properties

    static var sharedInstance: ZendeskUtils = ZendeskUtils()

    var zendeskEnabled: Bool = false

    private var identityCreated = false
    private var userName: String?
    private var userEmail: String?

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
                ZendeskUtils.enableZendesk(false)
                return
        }

        ZDKConfig.instance().initialize(withAppId: appId,
                                        zendeskUrl: url,
                                        clientId: clientId)

        ZendeskUtils.enableZendesk(true)
    }

    func createIdentity() {

        /*
         Steps to selecting which account to use:
         1. If there is a WordPress.com account, use that.
         2. If not, check if we’ve saved user information in User Defaults. If so, use that.
         3. If not, get user information from the selected site, save it to User Defaults, and use it.
         */

        let context = ContextManager.sharedInstance().mainContext
        let accountService = AccountService(managedObjectContext: context)

        if let defaultAccount = accountService.defaultWordPressComAccount() {
            ZendeskUtils.getUserInformationFrom(wpAccount: defaultAccount)
        } else if let savedProfile = UserDefaults.standard.dictionary(forKey: Constants.zendeskProfileUDKey) {
            ZendeskUtils.getUserInformationFrom(savedProfile: savedProfile)
        } else {
            let blogService = BlogService(managedObjectContext: context)

            guard let blog = blogService.lastUsedBlog() else {
                return
            }

            if let jetpackState = blog.jetpack, jetpackState.isConnected {
                ZendeskUtils.getUserInformationFrom(jetpackState: jetpackState)
                ZendeskUtils.saveProfileToUD()
            }
            else {
                ZendeskUtils.getUserInformationFrom(blog: blog)
                ZendeskUtils.saveProfileToUD()
            }
        }

        // Create ZD Identity with user information.
        let zendeskIdentity = ZDKAnonymousIdentity()
        zendeskIdentity.email = userEmail
        zendeskIdentity.name = userName
        ZDKConfig.instance().userIdentity = zendeskIdentity
        ZendeskUtils.sharedInstance.identityCreated = true
    }

    func showHelpCenter(from controller: UIViewController) {

        if !ZendeskUtils.sharedInstance.identityCreated {
            return
        }

        guard let helpCenterContentModel = ZDKHelpCenterOverviewContentModel.defaultContent() else {
            return
        }

        helpCenterContentModel.groupType = .category
        helpCenterContentModel.groupIds = [Constants.mobileCategoryID]
        helpCenterContentModel.labels = [Constants.articleLabel]

        let presentInController = ZendeskUtils.configureViewController(controller)
        ZDKHelpCenter.presentOverview(presentInController, with: helpCenterContentModel)
    }

    func showNewRequest(from controller: UIViewController) {

        if !ZendeskUtils.sharedInstance.identityCreated {
            return
        }

        let presentInController = ZendeskUtils.configureViewController(controller)
        ZDKRequests.presentRequestCreation(with: presentInController)
    }

    func showTicketList(from controller: UIViewController) {

        if !ZendeskUtils.sharedInstance.identityCreated {
            return
        }

        let presentInController = ZendeskUtils.configureViewController(controller)
        ZDKRequests.presentRequestList(with: presentInController)
    }

    func createRequest() {

        if !ZendeskUtils.sharedInstance.identityCreated {
            return
        }

        ZDKRequests.configure { (account, requestCreationConfig) in

            guard let requestCreationConfig = requestCreationConfig else {
                return
            }

            // Set Zendesk ticket form to use
            ZDKConfig.instance().ticketFormId = TicketFieldIDs.form as NSNumber

            // Set form field values
            var ticketFields = [ZDKCustomField]()
            ticketFields.append(ZDKCustomField(fieldId: TicketFieldIDs.appVersion as NSNumber, andValue: ZendeskUtils.appVersion))
            ticketFields.append(ZDKCustomField(fieldId: TicketFieldIDs.allBlogs as NSNumber, andValue: ZendeskUtils.getBlogInformation()))
            ticketFields.append(ZDKCustomField(fieldId: TicketFieldIDs.deviceFreeSpace as NSNumber, andValue: ZendeskUtils.getDeviceFreeSpace()))
            ticketFields.append(ZDKCustomField(fieldId: TicketFieldIDs.networkInformation as NSNumber, andValue: ZendeskUtils.getNetworkInformation()))
            ticketFields.append(ZDKCustomField(fieldId: TicketFieldIDs.logs as NSNumber, andValue: ZendeskUtils.getLogFile()))
            ZDKConfig.instance().customTicketFields = ticketFields

            // Set tags
            requestCreationConfig.tags = ZendeskUtils.getTags()

            // Set the ticket subject
            requestCreationConfig.subject = Constants.ticketSubject
        }
    }

}

// MARK: - Private Extension

private extension ZendeskUtils {

    static func enableZendesk(_ enabled: Bool) {
        ZendeskUtils.sharedInstance.zendeskEnabled = enabled
        DDLogInfo("Zendesk Enabled: \(enabled)")
    }

    static func configureViewController(_ controller: UIViewController) -> UIViewController {
        // If the controller is a UIViewController, set the modal display for iPad.
        // If the controller is a UINavigationController, do nothing as the ZD views will inherit from that.
        if !controller.isKind(of: UINavigationController.self) && WPDeviceIdentification.isiPad() {
            controller.modalPresentationStyle = .formSheet
            controller.modalTransitionStyle = .crossDissolve
        }
        return controller
    }

    // MARK: - Get User Information

    static func getUserInformationFrom(jetpackState: JetpackState) {
        ZendeskUtils.sharedInstance.userName = jetpackState.connectedUsername
        ZendeskUtils.sharedInstance.userEmail = jetpackState.connectedEmail
    }

    static func getUserInformationFrom(blog: Blog) {
        ZendeskUtils.sharedInstance.userName = blog.username
        // TODO - get email
    }

    static func getUserInformationFrom(wpAccount: WPAccount) {

        guard let api = wpAccount.wordPressComRestApi else {
            return
        }

        let service = AccountSettingsService(userID: wpAccount.userID.intValue, api: api)

        guard let accountSettings = service.settings else {
            return
        }

        ZendeskUtils.sharedInstance.userEmail = wpAccount.email
        ZendeskUtils.sharedInstance.userName = wpAccount.username
        if accountSettings.firstName.count > 0 || accountSettings.lastName.count > 0 {
            ZendeskUtils.sharedInstance.userName = (accountSettings.firstName + " " + accountSettings.lastName).trim()
        }
    }

    static func getUserInformationFrom(savedProfile: [String: Any]) {

        if let savedEmail = savedProfile[Constants.profileEmailKey] as? String {
            ZendeskUtils.sharedInstance.userEmail = savedEmail
        }

        if let savedName = savedProfile[Constants.profileNameKey] as? String {
            ZendeskUtils.sharedInstance.userName = savedName
        }
    }

    // MARK: - Save to User Defaults

    static func saveProfileToUD() {
        var userProfile = [String: String]()
        userProfile[Constants.profileEmailKey] = ZendeskUtils.sharedInstance.userEmail
        userProfile[Constants.profileNameKey] = ZendeskUtils.sharedInstance.userName

        UserDefaults.standard.set(userProfile, forKey: Constants.zendeskProfileUDKey)
        UserDefaults.standard.synchronize()
    }

    // MARK: - Data Helpers

    static func getDeviceFreeSpace() -> String {

        guard let resourceValues = try? URL(fileURLWithPath: "/").resourceValues(forKeys: [.volumeAvailableCapacityKey]),
            let capacity = resourceValues.volumeAvailableCapacity else {
                return Constants.unknownValue
        }

        // format string using human readable units. ex: 1.5 GB
        return ByteCountFormatter.string(fromByteCount: Int64(capacity), countStyle: .binary)
    }

    static func getLogFile() -> String {

        guard let appDelegate = UIApplication.shared.delegate as? WordPressAppDelegate,
            let fileLogger = appDelegate.logger.fileLogger,
            let logFileInformation = fileLogger.logFileManager.sortedLogFileInfos.first,
            let logData = try? Data(contentsOf: URL(fileURLWithPath: logFileInformation.filePath)),
            let logText = String.init(data: logData, encoding: .utf8) else {
            return ""
        }

        return logText
    }

    static func getBlogInformation() -> String {

        let blogService = BlogService(managedObjectContext: ContextManager.sharedInstance().mainContext)

        guard let allBlogs = blogService.blogsForAllAccounts() as? [Blog], allBlogs.count > 0 else {
            return Constants.noValue
        }

        return (allBlogs.map { $0.logDescription() }).joined(separator: Constants.blogSeperator)
    }

    static func getTags() -> [String] {

        var tags = [String]()

        let accountService = AccountService.init(managedObjectContext: ContextManager.sharedInstance().mainContext)

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

    static func getNetworkInformation() -> String {

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
        static let zendeskProfileUDKey = "wp_zendesk_profile"
        static let profileEmailKey = "email"
        static let profileNameKey = "name"
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
