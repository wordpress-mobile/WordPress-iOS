import CoreData
import WordPressKit
import WordPressShared

public enum SiteVisibility: Int {
    case `private` = -1
    case hidden = 0
    case `public` = 1
    case unknown = 999999
}

@objc(Blog)
public class Blog: NSManagedObject {

    // MARK: - Core Data Attributes

    @NSManaged public var accountForDefaultBlog: WPAccount?
    @available(*, deprecated, message: "Use dotComID instead")
    @NSManaged public var blogID: NSNumber?
    @NSManaged public var url: String?
    @NSManaged public var restApiRootURL: String?
    @NSManaged public var apiKey: String?
    @NSManaged public var organizationID: NSNumber?
    @NSManaged public var hasDomainCredit: Bool
    @NSManaged public var currentThemeId: String?
    @NSManaged public var lastCommentsSync: Date?
    @NSManaged public var lastUpdateWarning: String?
    @NSManaged public var options: [AnyHashable: Any]?
    @NSManaged public var postFormats: [AnyHashable: Any]?
    @NSManaged public var account: WPAccount?
    @NSManaged public var isAdmin: Bool
    @NSManaged public var isMultiAuthor: Bool
    @NSManaged public var isHostedAtWPcom: Bool
    @NSManaged public var icon: String?
    @NSManaged public var username: String?
    @NSManaged public var settings: BlogSettings?
    @NSManaged public var publicizeInfo: PublicizeInfo?
    @NSManaged public var planID: NSNumber?
    @NSManaged public var planTitle: String?
    @NSManaged public var planActiveFeatures: [String]?
    @NSManaged public var hasPaidPlan: Bool
    @NSManaged public var capabilities: [AnyHashable: Any]?
    @NSManaged public var userID: NSNumber?
    @NSManaged public var quotaSpaceAllowed: NSNumber?
    @NSManaged public var quotaSpaceUsed: NSNumber?
    @NSManaged public var rawTaxonomies: Data?

    // MARK: - Core Data Relationships

    @NSManaged public var posts: Set<AbstractPost>?
    @NSManaged public var categories: Set<PostCategory>?
    @NSManaged public var tags: Set<PostTag>?
    @NSManaged public var comments: Set<Comment>?
    @NSManaged public var connections: Set<PublicizeConnection>?
    @NSManaged public var domains: Set<ManagedDomain>?
    @NSManaged public var inviteLinks: Set<InviteLinks>?
    @NSManaged public var themes: Set<Theme>?
    @NSManaged public var media: Set<Media>?
    @NSManaged public var userSuggestions: Set<UserSuggestion>?
    @NSManaged public var siteSuggestions: Set<SiteSuggestion>?
    @NSManaged public var menus: NSOrderedSet?
    @NSManaged public var menuLocations: NSOrderedSet?
    @NSManaged public var roles: Set<Role>?
    @NSManaged public var postTypes: Set<PostType>?
    @NSManaged public var pageTemplateCategories: Set<PageTemplateCategory>?
    @NSManaged public var sharingButtons: NSSet?

    // MARK: - Non-Core Data Properties

    private var _xmlrpcApi: WordPressOrgXMLRPCApi?
    private var _selfHostedSiteRestApi: WordPressOrgRestApi?

    @objc public var xmlrpcApi: WordPressOrgXMLRPCApi? {
        get {
            if _xmlrpcApi == nil, let endpoint = xmlrpc.flatMap(URL.init(string:)) {
                _xmlrpcApi = WordPressOrgXMLRPCApi(endpoint: endpoint, userAgent: WPUserAgent.wordPress())
            }
            return _xmlrpcApi
        }
        set {
            _xmlrpcApi = newValue
        }
    }

    @objc public var selfHostedSiteRestApi: WordPressOrgRestApi? {
        if _selfHostedSiteRestApi == nil {
            _selfHostedSiteRestApi = account == nil ? WordPressOrgRestApi(blog: self) : nil
        }
        return _selfHostedSiteRestApi
    }

    // MARK: - NSManagedObject Lifecycle

    public override func willSave() {
        super.willSave()

        // The `dotComID` getter has special code to _update_ `blogID` value.
        // This is a weird patch to make sure `blogID` is set to a correct value.
        //
        // It's important that calling `dotComID` repeatedly only updates
        // `Blog` instance once, which is the case at the moment.
        _ = dotComID
    }

    public override func prepareForDeletion() {
        super.prepareForDeletion()

        // Delete stored password in the keychain for self-hosted sites.
        if let username, !username.isEmpty, let xmlrpc, !xmlrpc.isEmpty {
            password = nil
        }

        if account == nil {
            try? deleteApplicationToken()
        }

        _xmlrpcApi?.invalidateAndCancelTasks()
        _selfHostedSiteRestApi?.invalidateAndCancelTasks()

        // Remove the self-hosted site cookies from the shared cookie storage.
        if account == nil, let siteURL = url.flatMap(URL.init(string:)) {
            let cookieJar = HTTPCookieStorage.shared
            for cookie in cookieJar.cookies(for: siteURL) ?? [] {
                cookieJar.deleteCookie(cookie)
            }
        }
    }

    public override func didTurnIntoFault() {
        super.didTurnIntoFault()

        xmlrpcApi = nil
        _selfHostedSiteRestApi = nil
        NotificationCenter.default.removeObserver(self)
    }
}
