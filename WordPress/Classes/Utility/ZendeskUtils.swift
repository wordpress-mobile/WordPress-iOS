import Foundation
import ZendeskSDK
import CoreTelephony
import WordPressAuthenticator

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
    
    // Specifically for WPError, which has the sourceTag as a String.
    private var sourceTagDescription: String?
    
    private var userName: String?
    private var userEmail: String?
    private var deviceID: String?
    private var usingAnonymousIDForHelpCenter = false
    
    private static var zdAppID: String?
    private static var zdUrl: String?
    private static var zdClientId: String?
    private static var presentInController: UIViewController?
    
    private static var appVersion: String {
        return Bundle.main.shortVersionString() ?? Constants.unknownValue
    }
    
    // MARK: - Public Methods
    
    @objc static func setup() {
        guard getZendeskCredentials() == true else {
            return
        }
        
        ZDKConfig.instance().initialize(withAppId: zdAppID,
                                        zendeskUrl: zdUrl,
                                        clientId: zdClientId)
        
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
    }
    
    // MARK: - Show Zendesk Views
    
    /// Displays the Zendesk Help Center from the given controller, filtered by the mobile category and articles labelled as iOS.
    ///
    func showHelpCenterIfPossible(from controller: UIViewController, with sourceTag: WordPressSupportSourceTag? = nil) {
        
        ZendeskUtils.configureViewController(controller)
        
        // Since user information is not needed to display the Help Center,
        // if a user identity has not been created, create an empty identity.
        if ZDKConfig.instance().userIdentity == nil {
            let zendeskIdentity = ZDKAnonymousIdentity()
            ZDKConfig.instance().userIdentity = zendeskIdentity
            usingAnonymousIDForHelpCenter = true
        } else {
            usingAnonymousIDForHelpCenter = false
        }
        
        self.sourceTag = sourceTag
        
        guard let helpCenterContentModel = ZDKHelpCenterOverviewContentModel.defaultContent() else {
            DDLogInfo("Zendesk helpCenterContentModel creation failed.")
            return
        }
        
        helpCenterContentModel.groupType = .category
        helpCenterContentModel.groupIds = [Constants.mobileCategoryID]
        helpCenterContentModel.labels = [Constants.articleLabel]
        
        // Set the ability to 'Contact Us' from the Help Center according to usingAnonymousIDForHelpCenter.
        ZDKHelpCenter.setUIDelegate(self)
        _ = active()
        
        ZDKHelpCenter.presentOverview(ZendeskUtils.presentInController, with: helpCenterContentModel)
    }
    
    /// Displays the Zendesk New Request view from the given controller, for users to submit new tickets.
    ///
    func showNewRequestIfPossible(from controller: UIViewController, with sourceTag: WordPressSupportSourceTag? = nil) {
        
        ZendeskUtils.configureViewController(controller)
        
        ZendeskUtils.createIdentity { success in
            guard success else {
                return
            }
            
            self.sourceTag = sourceTag
            
            ZDKRequests.presentRequestCreation(with: ZendeskUtils.presentInController)
            self.createRequest()
        }
    }
    
    /// Displays the Zendesk Request List view from the given controller, allowing user to access their tickets.
    ///
    func showTicketListIfPossible(from controller: UIViewController, with sourceTag: WordPressSupportSourceTag? = nil) {
        
        ZendeskUtils.configureViewController(controller)
        
        ZendeskUtils.createIdentity { success in
            guard success else {
                return
            }
            
            self.sourceTag = sourceTag
            
            ZDKRequests.presentRequestList(with: ZendeskUtils.presentInController)
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
    
    /// This handles in-app Zendesk push notifications.
    /// If a Zendesk view is being displayed, an alert will appear allowing
    /// the user to view the updated ticket.
    ///
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
    
    /// This handles all Zendesk push notifications. (The in-app flow goes through here as well.)
    /// When a notification is received, an NSNotification is posted to allow
    /// the various indicators to be displayed.
    ///
    static func pushNotificationReceived() {
        unreadNotificationsCount += 1
        saveUnreadCountToUD()
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
        saveUnreadCountToUD()
        postNotificationRead()
    }
    
    // MARK: - Helpers
    
    /// Specifically for WPError, which is ObjC & has the sourceTag as a String.
    ///
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
                toggleZendesk(enabled: false)
                return false
        }
        
        zdAppID = appId
        zdUrl = url
        zdClientId = clientId
        return true
    }
    
    static func toggleZendesk(enabled: Bool) {
        zendeskEnabled = enabled
        DDLogInfo("Zendesk Enabled: \(enabled)")
    }
    
    static func createIdentity(completion: @escaping (Bool) -> Void) {
        
        /*
         Steps to selecting which account to use:
         1. If there is a WordPress.com account, use that.
         2. If not, check if we’ve saved user information in User Defaults. If so, use that.
         3. If not, get user information from the selected site, save it to User Defaults, and use it.
         
         If the user is not logged in:
         1. Check if we’ve saved user information in User Defaults. If so, use that.
         2. If not, we don't have any user information. Prompt the user for it.
         */
        
        let context = ContextManager.sharedInstance().mainContext
        
        // 1. Check for WP account
        let accountService = AccountService(managedObjectContext: context)
        if let defaultAccount = accountService.defaultWordPressComAccount() {
            DDLogDebug("Using defaultAccount for Zendesk identity.")
            getUserInformationFrom(wpAccount: defaultAccount)
            createZendeskIdentity()
            completion(true)
            return
        }
        
        // 2. Check User Defaults
        if let savedProfile = UserDefaults.standard.dictionary(forKey: Constants.zendeskProfileUDKey) {
            DDLogDebug("Using User Defaults for Zendesk identity.")
            getUserInformationFrom(savedProfile: savedProfile)
            createZendeskIdentity()
            completion(true)
            return
        }
        
        // 3. Use information from selected site.
        let blogService = BlogService(managedObjectContext: context)
        
        guard let blog = blogService.lastUsedBlog() else {
            
            // The user is not logged in. Check User Defaults for manually entered information.
            if let savedProfile = UserDefaults.standard.dictionary(forKey: Constants.zendeskNoAccountProfileUDKey) {
                DDLogDebug("Using manually entered information from User Defaults for Zendesk identity.")
                getUserInformationFrom(savedProfile: savedProfile)
                createZendeskIdentity()
                completion(true)
                return
            }
            
            // We have no user information. Prompt user for it.
            promptUserForInformation { success in
                guard success else {
                    DDLogInfo("No user information to create Zendesk identity with.")
                    completion(false)
                    return
                }
                
                DDLogDebug("Using manually entered information for Zendesk identity.")
                saveNoAccountProfileToUD()
                createZendeskIdentity()
                completion(true)
                return
            }
            return
        }
        
        // 3a. Jetpack site
        if let jetpackState = blog.jetpack, jetpackState.isConnected {
            DDLogDebug("Using Jetpack site for Zendesk identity.")
            getUserInformationFrom(jetpackState: jetpackState)
            createZendeskIdentity()
            saveAccountProfileToUD()
            completion(true)
            return
            
        }
        
        // 3b. self-hosted site
        ZendeskUtils.getUserInformationFrom(blog: blog) {
            DDLogDebug("Using self-hosted for Zendesk identity.")
            createZendeskIdentity()
            saveAccountProfileToUD()
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
        registerDeviceIfNeeded()
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
    
    static func configureViewController(_ controller: UIViewController) {
        // If the controller is a UIViewController, set the modal display for iPad.
        // If the controller is a UINavigationController, do nothing as the ZD views will inherit from that.
        if !controller.isKind(of: UINavigationController.self) && WPDeviceIdentification.isiPad() {
            controller.modalPresentationStyle = .formSheet
            controller.modalTransitionStyle = .crossDissolve
        }
        presentInController = controller
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
    
    static func saveAccountProfileToUD() {
        saveProfileToUDFor(key: Constants.zendeskProfileUDKey)
        
        // Since we have account information, remove no account information.
        UserDefaults.standard.removeObject(forKey: Constants.zendeskNoAccountProfileUDKey)
    }
    
    static func saveNoAccountProfileToUD() {
        saveProfileToUDFor(key: Constants.zendeskNoAccountProfileUDKey)
    }
    
    static func saveProfileToUDFor(key: String) {
        var userProfile = [String: String]()
        userProfile[Constants.profileEmailKey] = ZendeskUtils.sharedInstance.userEmail
        userProfile[Constants.profileNameKey] = ZendeskUtils.sharedInstance.userName
        
        UserDefaults.standard.set(userProfile, forKey: key)
        UserDefaults.standard.synchronize()
    }
    
    static func saveUnreadCountToUD() {
        UserDefaults.standard.set(unreadNotificationsCount, forKey: Constants.userDefaultsZendeskUnreadNotifications)
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
    
    // MARK: - NSNotification Helpers
    
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
    
    static func promptUserForInformation(completion: @escaping (Bool) -> Void) {
        
        let alertController = UIAlertController(title: nil,
                                                message: nil,
                                                preferredStyle: .alert)
        
        alertController.setValue(NSAttributedString(string: LocalizedText.alertMessage, attributes: [.font: WPStyleGuide.subtitleFont()]),
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
            ZendeskUtils.sharedInstance.userName = alertController?.textFields?.last?.text ?? generateDisplayName(from: email)
            completion(true)
            return
        }
        
        // Disable Submit until a valid Email is entered.
        submitAction.isEnabled = false
        // Make Submit button bold.
        alertController.preferredAction = submitAction
        
        // Email Text Field
        alertController.addTextField(configurationHandler: { textField in
            textField.clearButtonMode = .always
            textField.placeholder = LocalizedText.emailPlaceholder
            
            textField.addTarget(self,
                                action: #selector(emailTextFieldDidChange),
                                for: UIControlEvents.editingChanged)
        })
        
        // Name Text Field
        alertController.addTextField { textField in
            textField.clearButtonMode = .always
            textField.placeholder = LocalizedText.namePlaceholder
        }
        
        // Show alert
        presentInController?.present(alertController, animated: true, completion: nil)
    }
    
    @objc static func emailTextFieldDidChange(_ textField: UITextField) {
        guard let alertController = presentInController?.presentedViewController as? UIAlertController,
            let email = alertController.textFields?.first?.text,
            let submitAction = alertController.actions.last else {
                return
        }
        
        submitAction.isEnabled = EmailFormatValidator.validate(string: email)
        updateNameFieldForEmail(email)
    }
    
    static func updateNameFieldForEmail(_ email: String) {
        guard let alertController = presentInController?.presentedViewController as? UIAlertController,
            let nameField = alertController.textFields?.last else {
                return
        }
        
        guard !email.isEmpty else {
            return
        }
        
        nameField.text = generateDisplayName(from: email)
    }
    
    static func generateDisplayName(from rawEmail: String) -> String {
        
        // Generate Name, using the same format as Signup.
        
        // step 1: lower case
        let email = rawEmail.lowercased()
        // step 2: remove the @ and everything after
        let localPart = email.split(separator: "@")[0]
        // step 3: remove all non-alpha characters
        let localCleaned = localPart.replacingOccurrences(of: "[^A-Za-z/.]", with: "", options: .regularExpression)
        // step 4: turn periods into spaces
        let nameLowercased = localCleaned.replacingOccurrences(of: ".", with: " ")
        // step 5: capitalize
        let autoDisplayName = nameLowercased.capitalized
        
        return autoDisplayName
    }
    
    // MARK: - Constants
    
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
        static let zendeskNoAccountProfileUDKey = "wp_zendesk_profile_no_account"
        static let profileEmailKey = "email"
        static let profileNameKey = "name"
        static let userDefaultsZendeskUnreadNotifications = "wp_zendesk_unread_notifications"
    }
    
    struct TicketFieldIDs {
        static let form: UInt64 = 360000010286
        static let appVersion: UInt64 = 360000086866
        static let allBlogs: UInt64 = 360000087183
        static let deviceFreeSpace: UInt64 = 360000089123
        static let networkInformation: UInt64 = 360000086966
        static let logs: UInt64 = 22871957
    }
    
    struct LocalizedText {
        static let alertMessage = NSLocalizedString("To continue please enter your email address and name.", comment: "Instructions for alert asking for email and name.")
        static let alertSubmit = NSLocalizedString("OK", comment: "Submit button on prompt for user information.")
        static let alertCancel = NSLocalizedString("Cancel", comment: "Cancel prompt for user information.")
        static let emailPlaceholder = NSLocalizedString("Email", comment: "Email address text field placeholder")
        static let namePlaceholder = NSLocalizedString("Name", comment: "Name text field placeholder")
    }
    
}

// MARK: - ZDKHelpCenterConversationsUIDelegate

extension ZendeskUtils: ZDKHelpCenterConversationsUIDelegate {
    
    func navBarConversationsUIType() -> ZDKNavBarConversationsUIType {
        // When ZDKContactUsVisibility is on, use the default right nav bar label.
        return .localizedLabel
    }
    
    func active() -> ZDKContactUsVisibility {
        // If the user is not logged in, disable 'Contact Us' via the Help Center and Article view.
        if usingAnonymousIDForHelpCenter {
            return .off
        }
        
        return .articleListAndArticle
    }
    
    func conversationsBarButtonImage() -> UIImage! {
        // Nothing to do here, but this method is required for ZDKHelpCenterConversationsUIDelegate.
        return UIImage()
    }
    
}
