import Foundation
import ZendeskSDK
import CoreTelephony
import WordPressAuthenticator

extension NSNotification.Name {
    static let ZendeskPushNotificationReceivedNotification = NSNotification.Name(rawValue: "ZendeskPushNotificationReceivedNotification")
}

@objc extension NSNotification {
    public static let ZendeskPushNotificationReceivedNotification = NSNotification.Name.ZendeskPushNotificationReceivedNotification
}

@objc class ZendeskUtils: NSObject {

    // MARK: - Properties

    static var sharedInstance: ZendeskUtils = ZendeskUtils()
    private override init() {}

    static var zendeskEnabled = false

    private var sourceTag: WordPressSupportSourceTag?

    // Specifically for WPError, which has the sourceTag as a String.
    private var sourceTagDescription: String?

    private var userName: String?
    private var userEmail: String?
    private var deviceID: String?

    private static var zdAppID: String?
    private static var zdUrl: String?
    private static var zdClientId: String?

    private static var appVersion: String {
        return Bundle.main.shortVersionString() ?? Constants.unknownValue
    }

    struct PushNotificationIdentifiers {
        static let key = "type"
        static let type = "zendesk"
    }

    // MARK: - Public Methods

    @objc static func setup() {
        guard getZendeskCredentials() == true else {
            return
        }

        ZDKConfig.instance().initialize(withAppId: zdAppID,
                                        zendeskUrl: zdUrl,
                                        clientId: zdClientId)

        ZendeskUtils.toggleZendesk(enabled: true)
    }

    // MARK: - Show Zendesk Views

    func showHelpCenterIfPossible(from controller: UIViewController, with sourceTag: WordPressSupportSourceTag? = nil) {
        ZendeskUtils.createIdentity { success in
            guard success else {
                // TODO: show error
                return
            }

            self.sourceTag = sourceTag

            guard let helpCenterContentModel = ZDKHelpCenterOverviewContentModel.defaultContent() else {
                DDLogInfo("Zendesk helpCenterContentModel creation failed.")
                return
            }

            helpCenterContentModel.groupType = .category
            helpCenterContentModel.groupIds = [Constants.mobileCategoryID]
            helpCenterContentModel.labels = [Constants.articleLabel]

            let presentInController = ZendeskUtils.configureViewController(controller)
            ZDKHelpCenter.presentOverview(presentInController, with: helpCenterContentModel)
        }
    }

    func showNewRequestIfPossible(from controller: UIViewController, with sourceTag: WordPressSupportSourceTag? = nil) {
        ZendeskUtils.createIdentity { success in
            guard success else {
                // TODO: show error
                return
            }

            self.sourceTag = sourceTag

            let presentInController = ZendeskUtils.configureViewController(controller)
            ZDKRequests.presentRequestCreation(with: presentInController)
            self.createRequest()
        }
    }

    func showTicketListIfPossible(from controller: UIViewController, with sourceTag: WordPressSupportSourceTag? = nil) {
        ZendeskUtils.createIdentity { success in
            guard success else {
                // TODO: show error
                return
            }

            self.sourceTag = sourceTag

            let presentInController = ZendeskUtils.configureViewController(controller)
            ZDKRequests.presentRequestList(with: presentInController)
        }
    }

    // MARK: - Device Registration

    static func setNeedToRegisterDevice(_ identifier: String) {
        ZendeskUtils.sharedInstance.deviceID = identifier
    }

    static func unregisterDevice(_ identifier: String) {
        ZDKConfig.instance().disablePush(identifier) { status, error in
            if let error = error {
                DDLogInfo("Zendesk couldn't unregistered device: \(identifier). Error: \(error)")
            } else {
                DDLogDebug("Zendesk successfully unregistered device: \(identifier)")
            }
        }
    }

    // MARK: - Push Notifications

    static func handlePushNotification(_ userInfo: NSDictionary) {

        guard zendeskEnabled == true,
            let payload = userInfo as? [AnyHashable: Any] else {
                DDLogInfo("Zendesk push notification payload invalid.")
                return
        }

        ZDKPushUtil.handlePush(payload,
                               for: UIApplication.shared,
                               presentationStyle: .formSheet,
                               layoutGuide: ZDKLayoutRespectTop,
                               withAppId: zdAppID,
                               zendeskUrl: zdUrl,
                               clientId: zdClientId)
    }

    static func pushNotificationReceived() {
        // Updating unread indicators should trigger UI updates, so send notification in main thread.
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .ZendeskPushNotificationReceivedNotification, object: nil)
        }
    }

    // MARK: - Helpers

    // Specifically for WPError, which is ObjC & has the sourceTag as a String.
    static func updateSourceTag(with description: String) {
        ZendeskUtils.sharedInstance.sourceTagDescription = description
    }

}

// MARK: - Private Extension

private extension ZendeskUtils {

    static func getZendeskCredentials() -> Bool {
        guard let appId = ApiCredentials.zendeskAppId(),
            let url = ApiCredentials.zendeskUrl(),
            let clientId = ApiCredentials.zendeskClientId(),
            appId.count > 0,
            url.count > 0,
            clientId.count > 0 else {
                DDLogInfo("Unable to get Zendesk credentials.")
                ZendeskUtils.toggleZendesk(enabled: false)
                return false
        }

        zdAppID = appId
        zdUrl = url
        zdClientId = clientId
        return true
    }

    static func toggleZendesk(enabled: Bool) {
        ZendeskUtils.zendeskEnabled = enabled
        DDLogInfo("Zendesk Enabled: \(enabled)")
    }

    static func createIdentity(completion: @escaping (Bool) -> Void) {

        /*
         Steps to selecting which account to use:
         1. If there is a WordPress.com account, use that.
         2. If not, check if we’ve saved user information in User Defaults. If so, use that.
         3. If not, get user information from the selected site, save it to User Defaults, and use it.
         */

        let context = ContextManager.sharedInstance().mainContext

        // 1. Check for WP account
        let accountService = AccountService(managedObjectContext: context)
        if let defaultAccount = accountService.defaultWordPressComAccount() {
            DDLogDebug("Using defaultAccount for Zendesk identity.")
            ZendeskUtils.getUserInformationFrom(wpAccount: defaultAccount)
            ZendeskUtils.createZendeskIdentity()
            completion(true)
            return
        }

        // 2. Check User Defaults
        if let savedProfile = UserDefaults.standard.dictionary(forKey: Constants.zendeskProfileUDKey) {
            DDLogDebug("Using User Defaults for Zendesk identity.")
            ZendeskUtils.getUserInformationFrom(savedProfile: savedProfile)
            ZendeskUtils.createZendeskIdentity()
            completion(true)
            return
        }

        // 3. Use information from selected site.
        let blogService = BlogService(managedObjectContext: context)

        guard let blog = blogService.lastUsedBlog() else {
            DDLogInfo("No Blog to create Zendesk identity with.")
            completion(false)
            return
        }

        // 3a. Jetpack site
        if let jetpackState = blog.jetpack, jetpackState.isConnected {
            DDLogDebug("Using Jetpack site for Zendesk identity.")
            ZendeskUtils.getUserInformationFrom(jetpackState: jetpackState)
            ZendeskUtils.createZendeskIdentity()
            ZendeskUtils.saveProfileToUD()
            completion(true)
            return

        }

        // 3b. self-hosted site
        ZendeskUtils.getUserInformationFrom(blog: blog) {
            DDLogDebug("Using self-hosted for Zendesk identity.")
            ZendeskUtils.createZendeskIdentity()
            ZendeskUtils.saveProfileToUD()
            completion(true)
            return
        }
    }

    static func createZendeskIdentity() {

        guard let userEmail = ZendeskUtils.sharedInstance.userEmail else {
            DDLogInfo("No user email to create Zendesk identity with.")
            ZDKConfig.instance().userIdentity = nil
            return
        }

        let zendeskIdentity = ZDKAnonymousIdentity()
        zendeskIdentity.email = userEmail
        zendeskIdentity.name = ZendeskUtils.sharedInstance.userName
        ZDKConfig.instance().userIdentity = zendeskIdentity
        DDLogDebug("Zendesk identity created with email '\(zendeskIdentity.email)' and name '\(zendeskIdentity.name)'.")
        ZendeskUtils.registerDeviceIfNeeded()
    }

    static func registerDeviceIfNeeded() {

        guard let deviceID = ZendeskUtils.sharedInstance.deviceID else {
                return
        }

        ZDKConfig.instance().enablePush(withDeviceID: deviceID) { pushResponse, error in
            if let error = error {
                DDLogInfo("Zendesk couldn't register device: \(deviceID). Error: \(error)")
            } else {
                ZendeskUtils.sharedInstance.deviceID = nil
                DDLogDebug("Zendesk successfully registered device: \(deviceID)")
            }
        }
    }

    func createRequest() {

        ZDKRequests.configure { (account, requestCreationConfig) in

            guard let requestCreationConfig = requestCreationConfig else {
                DDLogInfo("Zendesk requestCreationConfig creation failed.")
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

    static func getUserInformationFrom(blog: Blog, completion: @escaping () -> ()) {

        ZendeskUtils.sharedInstance.userName = blog.username

        // Get email address from remote profile
        guard let username = blog.username,
            let password = blog.password,
            let xmlrpc = blog.xmlrpc,
            let service = UsersService(username: username, password: password, xmlrpc: xmlrpc) else {
                return
        }

        service.fetchProfile { userProfile in
            guard let userProfile = userProfile else {
                completion()
                return
            }
            ZendeskUtils.sharedInstance.userEmail = userProfile.email
            completion()
        }
    }

    static func getUserInformationFrom(wpAccount: WPAccount) {

        guard let api = wpAccount.wordPressComRestApi else {
            DDLogInfo("Zendesk: No wordPressComRestApi.")
            return
        }

        let service = AccountSettingsService(userID: wpAccount.userID.intValue, api: api)

        guard let accountSettings = service.settings else {
            DDLogInfo("Zendesk: No accountSettings.")
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
            let logText = String(data: logData, encoding: .utf8) else {
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

        let context = ContextManager.sharedInstance().mainContext
        let blogService = BlogService(managedObjectContext: context)

        // If there are no sites, then the user has an empty WP account.
        guard let allBlogs = blogService.blogsForAllAccounts() as? [Blog], allBlogs.count > 0 else {
            return [Constants.wpComTag]
        }

        // Get all unique site plans
        var tags = allBlogs.compactMap { $0.planTitle }.unique

        // If any of the sites have jetpack installed, add jetpack tag.
        let jetpackBlog = allBlogs.first { $0.jetpack?.isInstalled == true }
        if let _ = jetpackBlog {
            tags.append(Constants.jetpackTag)
        }

        // If there is a WP account, add wpcom tag.
        let accountService = AccountService(managedObjectContext: context)
        if let _ = accountService.defaultWordPressComAccount() {
            tags.append(Constants.wpComTag)
        }

        // Add sourceTag
        if let sourceTagOrigin = ZendeskUtils.sharedInstance.sourceTag?.origin ?? ZendeskUtils.sharedInstance.sourceTagDescription {
            tags.append(sourceTagOrigin)
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
