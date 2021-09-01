import Foundation
import CoreTelephony
import WordPressAuthenticator
import WordPressKit

import SupportSDK
import ZendeskCoreSDK
import AutomatticTracks

extension NSNotification.Name {
    static let ZendeskPushNotificationReceivedNotification = NSNotification.Name(rawValue: "ZendeskPushNotificationReceivedNotification")
    static let ZendeskPushNotificationClearedNotification = NSNotification.Name(rawValue: "ZendeskPushNotificationClearedNotification")
}

@objc extension NSNotification {
    public static let ZendeskPushNotificationReceivedNotification = NSNotification.Name.ZendeskPushNotificationReceivedNotification
    public static let ZendeskPushNotificationClearedNotification = NSNotification.Name.ZendeskPushNotificationClearedNotification
}

/// This class provides the functionality to communicate with Zendesk for Help Center and support ticket interaction,
/// as well as displaying views for the Help Center, new tickets, and ticket list.
///
@objc class ZendeskUtils: NSObject {

    // MARK: - Public Properties

    static var sharedInstance: ZendeskUtils = ZendeskUtils()
    static var zendeskEnabled = false
    @objc static var unreadNotificationsCount = 0

    @objc static var showSupportNotificationIndicator: Bool {
        return unreadNotificationsCount > 0
    }

    struct PushNotificationIdentifiers {
        static let key = "type"
        static let type = "zendesk"
    }

    // MARK: - Private Properties

    private override init() {}
    private var sourceTag: WordPressSupportSourceTag?

    private var userName: String?
    private var userEmail: String?
    private var userNameConfirmed = false

    private var deviceID: String?
    private var haveUserIdentity = false
    private var alertNameField: UITextField?
    private var sitePlansCache = [Int: RemotePlanSimpleDescription]()

    private static var zdAppID: String?
    private static var zdUrl: String?
    private static var zdClientId: String?
    private weak var presentInController: UIViewController?

    private static var appVersion: String {
        return Bundle.main.shortVersionString() ?? Constants.unknownValue
    }

    private static var appLanguage: String {
        return Locale.preferredLanguages[0]
    }

    // MARK: - Public Methods

    @objc static func setup() {
        guard getZendeskCredentials() else {
            return
        }

        guard let appId = zdAppID,
            let url = zdUrl,
            let clientId = zdClientId else {
                DDLogInfo("Unable to set up Zendesk.")
                toggleZendesk(enabled: false)
                return
        }

        Zendesk.initialize(appId: appId, clientId: clientId, zendeskUrl: url)
        Support.initialize(withZendesk: Zendesk.instance)

        ZendeskUtils.fetchUserInformation()
        toggleZendesk(enabled: true)

        // User has accessed a single ticket view, typically via the Zendesk Push Notification alert.
        // In this case, we'll clear the Push Notification indicators.
        NotificationCenter.default.addObserver(self, selector: #selector(ticketViewed(_:)), name: NSNotification.Name(rawValue: ZDKAPI_CommentListStarting), object: nil)

        // Get unread notification count from User Defaults.
        unreadNotificationsCount = UserDefaults.standard.integer(forKey: Constants.userDefaultsZendeskUnreadNotifications)

        //If there are any, post NSNotification so the unread indicators are displayed.
        if unreadNotificationsCount > 0 {
            postNotificationReceived()
        }

        observeZendeskNotifications()
    }

    // MARK: - Show Zendesk Views

    /// Displays the Zendesk New Request view from the given controller, for users to submit new tickets.
    /// If the user's identity (i.e. contact info) was updated, inform the caller in the `identityUpdated` completion block.
    ///
    func showNewRequestIfPossible(from controller: UIViewController, with sourceTag: WordPressSupportSourceTag? = nil, identityUpdated: ((Bool) -> Void)? = nil) {

        presentInController = controller

        ZendeskUtils.createIdentity { success, newIdentity in
            guard success else {
                identityUpdated?(false)
                return
            }

            self.sourceTag = sourceTag
            self.trackSourceEvent(.supportNewRequestViewed)

            self.createRequest() { requestConfig in
                let newRequestController = RequestUi.buildRequestUi(with: [requestConfig])
                ZendeskUtils.showZendeskView(newRequestController)

                identityUpdated?(newIdentity)
            }
        }
    }

    /// Displays the Zendesk Request List view from the given controller, allowing user to access their tickets.
    /// If the user's identity (i.e. contact info) was updated, inform the caller in the `identityUpdated` completion block.
    ///
    func showTicketListIfPossible(from controller: UIViewController, with sourceTag: WordPressSupportSourceTag? = nil, identityUpdated: ((Bool) -> Void)? = nil) {

        presentInController = controller

        ZendeskUtils.createIdentity { success, newIdentity in
            guard success else {
                identityUpdated?(false)
                return
            }

            self.sourceTag = sourceTag
            self.trackSourceEvent(.supportTicketListViewed)

            // Get custom request configuration so new tickets from this path have all the necessary information.
            self.createRequest() { requestConfig in
                let requestListController = RequestUi.buildRequestList(with: [requestConfig])
                ZendeskUtils.showZendeskView(requestListController)

                identityUpdated?(newIdentity)
            }
        }
    }

    /// Displays an alert allowing the user to change their Support email address.
    ///
    func showSupportEmailPrompt(from controller: UIViewController, completion: @escaping (Bool) -> Void) {
        presentInController = controller

        ZendeskUtils.getUserInformationAndShowPrompt(withName: false) { success in
            completion(success)
        }
    }

    func cacheUnlocalizedSitePlans(accountService: AccountService? = nil, planService: PlanService? = nil) {
        let context = ContextManager.shared.mainContext
        let accountService = accountService ?? AccountService(managedObjectContext: context)
        guard let account = accountService.defaultWordPressComAccount() else {
            return
        }

        let planService = planService ?? PlanService(managedObjectContext: context)
        planService.getAllSitesNonLocalizedPlanDescriptionsForAccount(account, success: { plans in
            self.sitePlansCache = plans
        }, failure: { error in })
    }

    func createRequest(planServiceRemote: PlanServiceRemote? = nil,
                       siteID: Int? = nil,
                       completion: @escaping (RequestUiConfiguration) -> Void) {

        let requestConfig = RequestUiConfiguration()

        // Set Zendesk ticket form to use
        requestConfig.ticketFormID = TicketFieldIDs.form as NSNumber

        // Set form field values
        var ticketFields = [CustomField]()
        ticketFields.append(CustomField(fieldId: TicketFieldIDs.appVersion, value: ZendeskUtils.appVersion))
        ticketFields.append(CustomField(fieldId: TicketFieldIDs.allBlogs, value: ZendeskUtils.getBlogInformation()))
        ticketFields.append(CustomField(fieldId: TicketFieldIDs.deviceFreeSpace, value: ZendeskUtils.getDeviceFreeSpace()))
        ticketFields.append(CustomField(fieldId: TicketFieldIDs.networkInformation, value: ZendeskUtils.getNetworkInformation()))
        ticketFields.append(CustomField(fieldId: TicketFieldIDs.logs, value: ZendeskUtils.getEncryptedLogUUID()))
        ticketFields.append(CustomField(fieldId: TicketFieldIDs.currentSite, value: ZendeskUtils.getCurrentSiteDescription()))
        ticketFields.append(CustomField(fieldId: TicketFieldIDs.sourcePlatform, value: Constants.sourcePlatform))
        ticketFields.append(CustomField(fieldId: TicketFieldIDs.appLanguage, value: ZendeskUtils.appLanguage))

        ZendeskUtils.getZendeskMetadata(planServiceRemote: planServiceRemote, siteID: siteID) { result in
            var tags = ZendeskUtils.getTags()
            switch result {
            case .success(let metadata):
                guard let metadata = metadata else {
                    break
                }

                ticketFields.append(CustomField(fieldId: TicketFieldIDs.plan, value: metadata.plan))
                ticketFields.append(CustomField(fieldId: TicketFieldIDs.addOns, value: metadata.jetpackAddons))
                tags.append(contentsOf: metadata.jetpackAddons)
            case .failure(let error):
                DDLogError("Unable to fetch zendesk metadata - \(error.localizedDescription)")
            }
            requestConfig.customFields = ticketFields
            // Set tags
            requestConfig.tags = tags

            // Set the ticket subject
            requestConfig.subject = Constants.ticketSubject
            completion(requestConfig)
        }
    }

    // MARK: - Device Registration

    /// Sets the device ID to be registered with Zendesk for push notifications.
    /// Actual registration is done when a user selects one of the Zendesk views.
    ///
    static func setNeedToRegisterDevice(_ identifier: String) {
        ZendeskUtils.sharedInstance.deviceID = identifier
    }

    /// Unregisters the device ID from Zendesk for push notifications.
    ///
    static func unregisterDevice() {
        guard let zendeskInstance = Zendesk.instance else {
            DDLogInfo("No Zendesk instance. Unable to unregister device.")
            return
        }

        ZDKPushProvider(zendesk: zendeskInstance).unregisterForPush()
        DDLogInfo("Zendesk successfully unregistered stored device.")
    }

    // MARK: - Push Notifications

    /// This handles in-app Zendesk push notifications.
    /// If the updated ticket or the ticket list is being displayed,
    /// the view will be refreshed.
    ///
    static func handlePushNotification(_ userInfo: NSDictionary) {
        WPAnalytics.track(.supportReceivedResponseFromSupport)
        guard zendeskEnabled == true,
            let payload = userInfo as? [AnyHashable: Any],
            let requestId = payload["zendesk_sdk_request_id"] as? String else {
                DDLogInfo("Zendesk push notification payload invalid.")
                return
        }

        let _ = Support.instance?.refreshRequest(requestId: requestId)
    }

    /// This handles all Zendesk push notifications. (The in-app flow goes through here as well.)
    /// When a notification is received, an NSNotification is posted to allow
    /// the various indicators to be displayed.
    ///
    static func pushNotificationReceived() {
        unreadNotificationsCount += 1
        saveUnreadCount()
        postNotificationReceived()
    }

    /// When a user views the Ticket List, this is called to:
    /// - clear the notification count
    /// - update the application badge count
    /// - post an NSNotification so the various indicators can be cleared.
    ///
    static func pushNotificationRead() {
        UIApplication.shared.applicationIconBadgeNumber -= unreadNotificationsCount
        unreadNotificationsCount = 0
        saveUnreadCount()
        postNotificationRead()
    }

    // MARK: - Helpers

    /// Returns the user's Support email address.
    ///
    static func userSupportEmail() -> String? {
        return ZendeskUtils.sharedInstance.userEmail
    }

    /// Obtains user's name and email from first available source.
    ///
    static func fetchUserInformation() {
        // If user information already obtained, do nothing.
        guard !ZendeskUtils.sharedInstance.haveUserIdentity else {
            return
        }

        // Attempt to load from User Defaults.
        // If nothing in UD, get from sources in `getUserInformationIfAvailable`.
        if !loadUserProfile() {
            ZendeskUtils.getUserInformationIfAvailable {
                ZendeskUtils.createZendeskIdentity { success in
                    guard success else {
                        return
                    }
                    ZendeskUtils.sharedInstance.haveUserIdentity = true
                }
            }
        }
    }

}

// MARK: - Private Extension

private extension ZendeskUtils {

    static func getZendeskCredentials() -> Bool {

        let zdAppID = ApiCredentials.zendeskAppId
        let zdUrl = ApiCredentials.zendeskUrl
        let zdClientId = ApiCredentials.zendeskClientId

        guard
            !zdAppID.isEmpty,
            !zdUrl.isEmpty,
            !zdClientId.isEmpty
        else {
            DDLogInfo("Unable to get Zendesk credentials.")
            toggleZendesk(enabled: false)
            return false
        }

        self.zdAppID = zdAppID
        self.zdUrl = zdUrl
        self.zdClientId = zdClientId

        return true
    }

    static func toggleZendesk(enabled: Bool) {
        zendeskEnabled = enabled
        DDLogInfo("Zendesk Enabled: \(enabled)")
    }

    /// Creates a Zendesk Identity from user information.
    /// Returns two values in the completion block:
    ///     - Bool indicating there is an identity to use.
    ///     - Bool indicating if a _new_ identity was created.
    ///
    static func createIdentity(completion: @escaping (Bool, Bool) -> Void) {

        // If we already have an identity, and the user has confirmed it, do nothing.
        let haveUserInfo = ZendeskUtils.sharedInstance.haveUserIdentity && ZendeskUtils.sharedInstance.userNameConfirmed
        guard !haveUserInfo else {
                DDLogDebug("Using existing Zendesk identity: \(ZendeskUtils.sharedInstance.userEmail ?? ""), \(ZendeskUtils.sharedInstance.userName ?? "")")
                completion(true, false)
                return
        }

        // Prompt the user for information.
        ZendeskUtils.getUserInformationAndShowPrompt(withName: true) { success in
            completion(success, success)
        }
    }

    static func getUserInformationAndShowPrompt(withName: Bool, completion: @escaping (Bool) -> Void) {
        ZendeskUtils.getUserInformationIfAvailable {
            ZendeskUtils.promptUserForInformation(withName: withName) { success in
                guard success else {
                    DDLogInfo("No user information to create Zendesk identity with.")
                    completion(false)
                    return
                }

                ZendeskUtils.createZendeskIdentity { success in
                    guard success else {
                        DDLogInfo("Creating Zendesk identity failed.")
                        completion(false)
                        return
                    }
                    DDLogDebug("Using information from prompt for Zendesk identity.")
                    ZendeskUtils.sharedInstance.haveUserIdentity = true
                    completion(true)
                    return
                }
            }
        }
    }

    static func getUserInformationIfAvailable(completion: @escaping () -> ()) {

        /*
         Steps to selecting which account to use:
         1. If there is a WordPress.com account, use that.
         2. If not, use selected site.
         */

        let context = ContextManager.sharedInstance().mainContext

        // 1. Check for WP account
        let accountService = AccountService(managedObjectContext: context)
        if let defaultAccount = accountService.defaultWordPressComAccount() {
            DDLogDebug("Zendesk - Using defaultAccount for suggested identity.")
            getUserInformationFrom(wpAccount: defaultAccount)
            completion()
            return
        }

        // 2. Use information from selected site.
        let blogService = BlogService(managedObjectContext: context)

        guard let blog = blogService.lastUsedBlog() else {
            // We have no user information.
            completion()
            return
        }

        // 2a. Jetpack site
        if let jetpackState = blog.jetpack, jetpackState.isConnected {
            DDLogDebug("Zendesk - Using Jetpack site for suggested identity.")
            getUserInformationFrom(jetpackState: jetpackState)
            completion()
            return

        }

        // 2b. self-hosted site
        ZendeskUtils.getUserInformationFrom(blog: blog) {
            DDLogDebug("Zendesk - Using self-hosted for suggested identity.")
            completion()
            return
        }
    }

    static func createZendeskIdentity(completion: @escaping (Bool) -> Void) {

        guard let userEmail = ZendeskUtils.sharedInstance.userEmail else {
            DDLogInfo("No user email to create Zendesk identity with.")
            let identity = Identity.createAnonymous()
            Zendesk.instance?.setIdentity(identity)
            completion(false)
            return
        }

        let zendeskIdentity = Identity.createAnonymous(name: ZendeskUtils.sharedInstance.userName, email: userEmail)
        Zendesk.instance?.setIdentity(zendeskIdentity)
        DDLogDebug("Zendesk identity created with email '\(userEmail)' and name '\(ZendeskUtils.sharedInstance.userName ?? "")'.")
        registerDeviceIfNeeded()
        completion(true)
    }

    static func registerDeviceIfNeeded() {

        guard let deviceID = ZendeskUtils.sharedInstance.deviceID,
            let zendeskInstance = Zendesk.instance else {
                return
        }

        ZDKPushProvider(zendesk: zendeskInstance).register(deviceIdentifier: deviceID, locale: appLanguage) { (pushResponse, error) in
            if let error = error {
                DDLogInfo("Zendesk couldn't register device: \(deviceID). Error: \(error)")
            } else {
                ZendeskUtils.sharedInstance.deviceID = nil
                DDLogDebug("Zendesk successfully registered device: \(deviceID)")
            }
        }
    }



    // MARK: - View

    static func showZendeskView(_ zendeskView: UIViewController) {
        guard let presentInController = ZendeskUtils.sharedInstance.presentInController else {
            return
        }

        // Presenting in a modal instead of pushing onto an existing navigation stack
        // seems to fix this issue we were seeing when trying to add media to a ticket:
        // https://github.com/wordpress-mobile/WordPress-iOS/issues/11397
        let navController = UINavigationController(rootViewController: zendeskView)
        navController.modalPresentationStyle = .formSheet
        navController.modalTransitionStyle = .coverVertical
        presentInController.present(navController, animated: true)
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

    // MARK: - User Defaults

    static func saveUserProfile() {
        var userProfile = [String: String]()
        userProfile[Constants.profileEmailKey] = ZendeskUtils.sharedInstance.userEmail
        userProfile[Constants.profileNameKey] = ZendeskUtils.sharedInstance.userName
        DDLogDebug("Zendesk - saving profile to User Defaults: \(userProfile)")
        UserDefaults.standard.set(userProfile, forKey: Constants.zendeskProfileUDKey)
    }

    static func loadUserProfile() -> Bool {
        guard let userProfile = UserDefaults.standard.dictionary(forKey: Constants.zendeskProfileUDKey) else {
            return false
        }

        DDLogDebug("Zendesk - read profile from User Defaults: \(userProfile)")
        ZendeskUtils.sharedInstance.userEmail = userProfile.valueAsString(forKey: Constants.profileEmailKey)
        ZendeskUtils.sharedInstance.userName = userProfile.valueAsString(forKey: Constants.profileNameKey)
        ZendeskUtils.sharedInstance.userNameConfirmed = true

        ZendeskUtils.createZendeskIdentity { success in
            guard success else {
                return
            }
            DDLogDebug("Using User Defaults for Zendesk identity.")
            ZendeskUtils.sharedInstance.haveUserIdentity = true
        }

        return true
    }

    static func saveUnreadCount() {
        UserDefaults.standard.set(unreadNotificationsCount, forKey: Constants.userDefaultsZendeskUnreadNotifications)
    }

    // MARK: - Data Helpers

    static func getDeviceFreeSpace() -> String {

        guard let resourceValues = try? URL(fileURLWithPath: "/").resourceValues(forKeys: [.volumeAvailableCapacityKey]),
            let capacityBytes = resourceValues.volumeAvailableCapacity else {
                return Constants.unknownValue
        }

        // format string using human readable units. ex: 1.5 GB
        // Since ByteCountFormatter.string translates the string and has no locale setting,
        // do the byte conversion manually so the Free Space is in English.
        let sizeAbbreviations = ["bytes", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"]
        var sizeAbbreviationsIndex = 0
        var capacity = Double(capacityBytes)

        while capacity > 1024 {
            capacity /= 1024
            sizeAbbreviationsIndex += 1
        }

        let formattedCapacity = String(format: "%4.2f", capacity)
        let sizeAbbreviation = sizeAbbreviations[sizeAbbreviationsIndex]
        return "\(formattedCapacity) \(sizeAbbreviation)"
    }

    static func getEncryptedLogUUID() -> String {

        let fileLogger = WPLogger.shared().fileLogger
        let dataProvider = EventLoggingDataProvider.fromDDFileLogger(fileLogger)

        guard let logFilePath = dataProvider.logFilePath(forErrorLevel: .debug, at: Date()) else {
            return "Error: No log files found on device"
        }

        let logFile = LogFile(url: logFilePath)

        do {
            let delegate = EventLoggingDelegate()

            /// Some users may be opted out – let's inform support that this is the case (otherwise the UUID just wouldn't work)
            if UserSettings.userHasOptedOutOfCrashLogging {
                return "No log file uploaded: User opted out"
            }

            let eventLogging = EventLogging(dataSource: dataProvider, delegate: delegate)
            try eventLogging.enqueueLogForUpload(log: logFile)
        }
        catch let err {
            return "Error preparing log file: \(err.localizedDescription)"
        }

        return logFile.uuid
    }

    static func getCurrentSiteDescription() -> String {
        let blogService = BlogService(managedObjectContext: ContextManager.sharedInstance().mainContext)

        guard let blog = blogService.lastUsedBlog() else {
            return Constants.noValue
        }

        let url = blog.url ?? Constants.unknownValue
        return "\(url) (\(blog.stateDescription()))"
    }

    static func getBlogInformation() -> String {

        let blogService = BlogService(managedObjectContext: ContextManager.sharedInstance().mainContext)

        let allBlogs = blogService.blogsForAllAccounts()
        guard allBlogs.count > 0 else {
            return Constants.noValue
        }

        let blogInfo: [String] = allBlogs.map {
            var desc = $0.supportDescription()
            if let blogID = $0.dotComID, let plan = ZendeskUtils.sharedInstance.sitePlansCache[blogID.intValue] {
                desc = desc + "<Unlocalized Plan: \(plan.name) (\(plan.planID))>" // Do not localize this. :)
            }
            return desc
        }
        return blogInfo.joined(separator: Constants.blogSeperator)
    }

    static func getTags() -> [String] {

        let context = ContextManager.sharedInstance().mainContext
        let blogService = BlogService(managedObjectContext: context)
        let allBlogs = blogService.blogsForAllAccounts()
        var tags = [String]()

        // Add sourceTag
        if let sourceTagOrigin = ZendeskUtils.sharedInstance.sourceTag?.origin {
            tags.append(sourceTagOrigin)
        }

        // Add platformTag
        tags.append(Constants.platformTag)

        // If there are no sites, then the user has an empty WP account.
        guard allBlogs.count > 0 else {
            tags.append(Constants.wpComTag)
            return tags
        }

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



        // Add gutenbergIsDefault tag
        if let blog = blogService.lastUsedBlog() {
            if blog.isGutenbergEnabled {
                tags.append(Constants.gutenbergIsDefault)
            }
        }

        if let currentSite = blogService.lastUsedOrFirstBlog(), !currentSite.isHostedAtWPcom, !currentSite.isAtomic() {
            tags.append(Constants.mobileSelfHosted)
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

        let networkCarrier = CTTelephonyNetworkInfo().serviceSubscriberCellularProviders?.values.first
        let carrierName = networkCarrier?.carrierName ?? Constants.unknownValue
        let carrierCountryCode = networkCarrier?.isoCountryCode ?? Constants.unknownValue

        networkInformation.append("\(Constants.networkTypeLabel) \(networkType)")
        networkInformation.append("\(Constants.networkCarrierLabel) \(carrierName)")
        networkInformation.append("\(Constants.networkCountryCodeLabel) \(carrierCountryCode)")

        return networkInformation.joined(separator: "\n")
    }

    func trackSourceEvent(_ event: WPAnalyticsStat) {
        guard let sourceTag = sourceTag else {
            WPAnalytics.track(event)
            return
        }

        let properties = ["source": sourceTag.origin ?? sourceTag.name]
        WPAnalytics.track(event, withProperties: properties)
    }


    // MARK: - Push Notification Helpers

    static func postNotificationReceived() {
        // Updating unread indicators should trigger UI updates, so send notification in main thread.
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .ZendeskPushNotificationReceivedNotification, object: nil)
        }
    }

    static func postNotificationRead() {
        // Updating unread indicators should trigger UI updates, so send notification in main thread.
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .ZendeskPushNotificationClearedNotification, object: nil)
        }
    }

    @objc static func ticketViewed(_ notification: Foundation.Notification) {
        pushNotificationRead()
    }

    // MARK: - User Information Prompt

    static func promptUserForInformation(withName: Bool, completion: @escaping (Bool) -> Void) {

        let alertController = UIAlertController(title: nil,
                                                message: nil,
                                                preferredStyle: .alert)

        let alertMessage = withName ? LocalizedText.alertMessageWithName : LocalizedText.alertMessage
        alertController.setValue(NSAttributedString(string: alertMessage, attributes: [.font: WPStyleGuide.subtitleFont()]),
                                 forKey: "attributedMessage")

        // Cancel Action
        alertController.addCancelActionWithTitle(LocalizedText.alertCancel) { (_) in
            completion(false)
            return
        }

        // Submit Action
        let submitAction = alertController.addDefaultActionWithTitle(LocalizedText.alertSubmit) { [weak alertController] (_) in
            guard let email = alertController?.textFields?.first?.text else {
                completion(false)
                return
            }

            ZendeskUtils.sharedInstance.userEmail = email

            if withName {
                ZendeskUtils.sharedInstance.userName = alertController?.textFields?.last?.text
                ZendeskUtils.sharedInstance.userNameConfirmed = true
            }

            saveUserProfile()
            completion(true)
            return
        }

        // Enable Submit based on email validity.
        let email = ZendeskUtils.sharedInstance.userEmail ?? ""
        submitAction.isEnabled = EmailFormatValidator.validate(string: email)

        // Make Submit button bold.
        alertController.preferredAction = submitAction

        // Email Text Field
        alertController.addTextField(configurationHandler: { textField in
            textField.clearButtonMode = .always
            textField.placeholder = LocalizedText.emailPlaceholder
            textField.accessibilityLabel = LocalizedText.emailAccessibilityLabel
            textField.text = ZendeskUtils.sharedInstance.userEmail
            textField.delegate = ZendeskUtils.sharedInstance
            textField.isEnabled = false
            textField.keyboardType = .emailAddress

            textField.addTarget(self,
                                action: #selector(emailTextFieldDidChange),
                                for: UIControl.Event.editingChanged)
        })

        // Name Text Field
        if withName {
            alertController.addTextField { textField in
                textField.clearButtonMode = .always
                textField.placeholder = LocalizedText.namePlaceholder
                textField.accessibilityLabel = LocalizedText.nameAccessibilityLabel
                textField.text = ZendeskUtils.sharedInstance.userName
                textField.delegate = ZendeskUtils.sharedInstance
                textField.isEnabled = false
                ZendeskUtils.sharedInstance.alertNameField = textField
            }
        }

        // Show alert
        ZendeskUtils.sharedInstance.presentInController?.present(alertController, animated: true) {
            // Enable text fields only after the alert is shown so that VoiceOver will dictate the message first.
            alertController.textFields?.forEach { textField in
                textField.isEnabled = true
            }
        }
    }

    @objc static func emailTextFieldDidChange(_ textField: UITextField) {
        guard let alertController = ZendeskUtils.sharedInstance.presentInController?.presentedViewController as? UIAlertController,
            let email = alertController.textFields?.first?.text,
            let submitAction = alertController.actions.last else {
                return
        }

        submitAction.isEnabled = EmailFormatValidator.validate(string: email)
        updateNameFieldForEmail(email)
    }

    static func updateNameFieldForEmail(_ email: String) {
        guard !email.isEmpty else {
            return
        }

        // Find the name text field if it's being displayed.
        guard let alertController = ZendeskUtils.sharedInstance.presentInController?.presentedViewController as? UIAlertController,
              let textFields = alertController.textFields,
              textFields.count > 1,
              let nameField = textFields.last else {
            return
        }

        // If we don't already have the user's name, generate it from the email.
        if ZendeskUtils.sharedInstance.userName == nil {
            nameField.text = generateDisplayName(from: email)
        }
    }

    static func generateDisplayName(from rawEmail: String) -> String? {
        // Generate Name, using the same format as Signup.

        // step 1: lower case
        let email = rawEmail.lowercased()

        // step 2: remove the @ and everything after

        // Verify something exists before the @.
        guard email.first != "@",
              let localPart = email.split(separator: "@").first else {
            return nil
        }

        // step 3: remove all non-alpha characters
        let localCleaned = localPart.replacingOccurrences(of: "[^A-Za-z/.]", with: "", options: .regularExpression)
        // step 4: turn periods into spaces
        let nameLowercased = localCleaned.replacingOccurrences(of: ".", with: " ")
        // step 5: capitalize
        let autoDisplayName = nameLowercased.capitalized

        return autoDisplayName
    }

    // MARK: - Zendesk Notifications

    static func observeZendeskNotifications() {
        // Ticket Attachments
        NotificationCenter.default.addObserver(self, selector: #selector(ZendeskUtils.zendeskNotification(_:)),
                                               name: NSNotification.Name(rawValue: ZDKAPI_UploadAttachmentSuccess), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ZendeskUtils.zendeskNotification(_:)),
                                               name: NSNotification.Name(rawValue: ZDKAPI_UploadAttachmentError), object: nil)

        // New Ticket Creation
        NotificationCenter.default.addObserver(self, selector: #selector(ZendeskUtils.zendeskNotification(_:)),
                                               name: NSNotification.Name(rawValue: ZDKAPI_RequestSubmissionSuccess), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ZendeskUtils.zendeskNotification(_:)),
                                               name: NSNotification.Name(rawValue: ZDKAPI_RequestSubmissionError), object: nil)

        // Ticket Reply
        NotificationCenter.default.addObserver(self, selector: #selector(ZendeskUtils.zendeskNotification(_:)),
                                               name: NSNotification.Name(rawValue: ZDKAPI_CommentSubmissionSuccess), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ZendeskUtils.zendeskNotification(_:)),
                                               name: NSNotification.Name(rawValue: ZDKAPI_CommentSubmissionError), object: nil)

        // View Ticket List
        NotificationCenter.default.addObserver(self, selector: #selector(ZendeskUtils.zendeskNotification(_:)),
                                               name: NSNotification.Name(rawValue: ZDKAPI_RequestsError), object: nil)

        // View Individual Ticket
        NotificationCenter.default.addObserver(self, selector: #selector(ZendeskUtils.zendeskNotification(_:)),
                                               name: NSNotification.Name(rawValue: ZDKAPI_CommentListSuccess), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ZendeskUtils.zendeskNotification(_:)),
                                               name: NSNotification.Name(rawValue: ZDKAPI_CommentListError), object: nil)

        // Help Center
        NotificationCenter.default.addObserver(self, selector: #selector(ZendeskUtils.zendeskNotification(_:)),
                                               name: NSNotification.Name(rawValue: ZD_HC_SearchSuccess), object: nil)
    }

    @objc static func zendeskNotification(_ notification: Foundation.Notification) {
        switch notification.name.rawValue {
        case ZDKAPI_RequestSubmissionSuccess:
            WPAnalytics.track(.supportNewRequestCreated)
        case ZDKAPI_RequestSubmissionError:
            WPAnalytics.track(.supportNewRequestFailed)
        case ZDKAPI_UploadAttachmentSuccess:
            WPAnalytics.track(.supportNewRequestFileAttached)
        case ZDKAPI_UploadAttachmentError:
            WPAnalytics.track(.supportNewRequestFileAttachmentFailed)
        case ZDKAPI_CommentSubmissionSuccess:
            WPAnalytics.track(.supportTicketUserReplied)
        case ZDKAPI_CommentSubmissionError:
            WPAnalytics.track(.supportTicketUserReplyFailed)
        case ZDKAPI_RequestsError:
            WPAnalytics.track(.supportTicketListViewFailed)
        case ZDKAPI_CommentListSuccess:
            WPAnalytics.track(.supportTicketUserViewed)
        case ZDKAPI_CommentListError:
            WPAnalytics.track(.supportTicketViewFailed)
        case ZD_HC_SearchSuccess:
            WPAnalytics.track(.supportHelpCenterUserSearched)
        default:
            break
        }
    }

    // MARK: - Plans

    /// Retrieves the highest priority plan, if it exists
    /// - Returns: the highest priority plan found, or an empty string if none was found
    static func getHighestPriorityPlan(planService: PlanService? = nil) -> String {

        let availablePlans = getAvailablePlansWithPriority(planService: planService)
        if !ZendeskUtils.sharedInstance.sitePlansCache.isEmpty {
            let plans = Set(ZendeskUtils.sharedInstance.sitePlansCache.values.compactMap { $0.name })

            for availablePlan in availablePlans {
                if plans.contains(availablePlan.nonLocalizedName) {
                    return availablePlan.supportName
                }
            }
        } else {
            // fail safe: if the plan cache call fails for any reason, at least let's use the cached blogs
            // and compare the localized names
            let blogService = BlogService(managedObjectContext: ContextManager.shared.mainContext)
            let plans = Set(blogService.blogsForAllAccounts().compactMap { $0.planTitle })

            for availablePlan in availablePlans {
                if plans.contains(availablePlan.name) {
                    return availablePlan.supportName
                }
            }
        }
        return ""
    }

    /// Obtains the available plans, sorted by priority
    static func getAvailablePlansWithPriority(planService: PlanService? = nil) -> [SupportPlan] {
        let planService = planService ?? PlanService(managedObjectContext: ContextManager.shared.mainContext)
        return planService.allPlans().map {
            SupportPlan(priority: $0.supportPriority,
                        name: $0.shortname,
                        nonLocalizedName: $0.nonLocalizedShortname,
                        supportName: $0.supportName)

        }
        .sorted { $0.priority > $1.priority }
    }

    /// Retrieves up to date Zendesk metadata from the backend
    /// - Parameters:
    ///   - planServiceRemote: optional plan service remote. The default is used if none is passed
    ///   - siteID: optional site id. The current is used if none is passed
    ///   - completion: completion closure executed at the completion of the remote call
    static func getZendeskMetadata(planServiceRemote: PlanServiceRemote? = nil,
                                   siteID: Int? = nil,
                                   completion: @escaping (Result<ZendeskMetadata?, Error>) -> Void) {

        guard let service = planServiceRemote ?? defaultPlanServiceRemote,
              let validSiteID = siteID ?? currentSiteID else {

            // This is not considered an error condition, there's simply no ZendeskMetaData,
            // most likely because the user is logged out.
            completion(.success(nil))
            return
        }

        service.getZendeskMetadata(siteID: validSiteID, completion: { result in
            switch result {
            case .success(let metadata):
                completion(.success(metadata))
            case .failure(let error):
                completion(.failure(error))
            }
        })
    }

    /// Provides the default PlanServiceRemote to `getZendeskMetadata`
    private static var defaultPlanServiceRemote: PlanServiceRemote? {
        guard let api = AccountService(managedObjectContext: ContextManager.shared.mainContext)
                .defaultWordPressComAccount()?
                .wordPressComRestApi else {
            return nil
        }
        return PlanServiceRemote(wordPressComRestApi: api)
    }

    /// Provides the current site id to `getZendeskMetadata`, if it exists
    private static var currentSiteID: Int? {
        guard let siteID = BlogService(managedObjectContext: ContextManager.shared.mainContext)
                .lastUsedOrFirstBlog()?
                .dotComID else {
            return nil
        }
        return Int(truncating: siteID)
    }

    struct SupportPlan {
        let priority: Int
        let name: String
        let nonLocalizedName: String
        let supportName: String

        // used to resolve discrepancies of unlocalized names between endpoints
        let mappings = ["E-commerce": "eCommerce"]

        init(priority: Int16,
             name: String,
             nonLocalizedName: String,
             supportName: String) {

            self.priority = Int(priority)
            self.name = name
            self.nonLocalizedName = mappings[nonLocalizedName] ?? nonLocalizedName
            self.supportName = supportName
        }
    }


    // MARK: - Constants

    struct Constants {
        static let unknownValue = "unknown"
        static let noValue = "none"
        static let platformTag = "iOS"
        static let ticketSubject = AppConstants.Zendesk.ticketSubject
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
        static let userDefaultsZendeskUnreadNotifications = "wp_zendesk_unread_notifications"
        static let nameFieldCharacterLimit = 50
        static let sourcePlatform = AppConstants.zendeskSourcePlatform
        static let gutenbergIsDefault = "mobile_gutenberg_is_default"
        static let mobileSelfHosted = "selected_site_self_hosted"
    }

    enum TicketFieldIDs {
        // Zendesk expects this as NSNumber. However, it is defined as Int64 to satisfy 32-bit devices (ex: iPhone 5).
        // Which means it has to be converted to NSNumber when sending to Zendesk.
        static let form: Int64 = 360000010286
        static let plan: Int64 = 25175963
        static let appVersion: Int64 = 360000086866
        static let allBlogs: Int64 = 360000087183
        static let deviceFreeSpace: Int64 = 360000089123
        static let networkInformation: Int64 = 360000086966
        static let logs: Int64 = 22871957
        static let currentSite: Int64 = 360000103103
        static let sourcePlatform: Int64 = 360009311651
        static let appLanguage: Int64 = 360008583691
        static let addOns: Int64 = 360025010672
    }

    struct LocalizedText {
        static let alertMessageWithName = NSLocalizedString("To continue please enter your email address and name.", comment: "Instructions for alert asking for email and name.")
        static let alertMessage = NSLocalizedString("Please enter your email address.", comment: "Instructions for alert asking for email.")
        static let alertSubmit = NSLocalizedString("OK", comment: "Submit button on prompt for user information.")
        static let alertCancel = NSLocalizedString("Cancel", comment: "Cancel prompt for user information.")
        static let emailPlaceholder = NSLocalizedString("Email", comment: "Email address text field placeholder")
        static let emailAccessibilityLabel = NSLocalizedString("Email", comment: "Accessibility label for the Email text field.")
        static let namePlaceholder = NSLocalizedString("Name", comment: "Name text field placeholder")
        static let nameAccessibilityLabel = NSLocalizedString("Name", comment: "Accessibility label for the Email text field.")
    }

}

// MARK: - UITextFieldDelegate

extension ZendeskUtils: UITextFieldDelegate {

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard textField == ZendeskUtils.sharedInstance.alertNameField,
            let text = textField.text else {
                return true
        }

        let newLength = text.count + string.count - range.length
        return newLength <= Constants.nameFieldCharacterLimit
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard textField != ZendeskUtils.sharedInstance.alertNameField,
            let email = textField.text else {
            return true
        }

        return EmailFormatValidator.validate(string: email)
    }

}
