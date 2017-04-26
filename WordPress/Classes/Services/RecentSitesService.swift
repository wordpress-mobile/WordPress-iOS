import Foundation

/// Keep track of recently used sites
///
class RecentSitesService: NSObject {
    // We use the site's URL to identify a site
    typealias SiteIdentifierType = String

    // MARK: - Internal variables
    private let database: KeyValueDatabase
    private let databaseKey = "RecentSites"
    private let legacyLastUsedBlogKey = "LastUsedBlogURLDefaultsKey"
    @objc static let WPTouchedBlogNotification = "WPTouchedBlogNotification"

    /// The maximum number of recent sites (read only)
    ///
    let maxSiteCount = 3

    // MARK: - Initialization

    /// Initialize the service with the given database
    ///
    /// This initializer was meant for testing. You probably want to use the convenience `init()` that uses the standard UserDefaults as the database.
    ///
    init(database: KeyValueDatabase) {
        self.database = database
        super.init()
    }

    /// Initialize the service using the standard UserDefaults as the database.
    ///
    convenience override init() {
        self.init(database: UserDefaults() as KeyValueDatabase)
    }

    // MARK: - Public accessors

    /// Returns a list of recently used sites, up to maxSiteCount.
    ///
    var recentSites: [SiteIdentifierType] {
        return Array(allRecentSites.prefix(maxSiteCount))
    }

    /// Returns a list of all the recently used sites.
    ///
    var allRecentSites: [SiteIdentifierType] {
        if let sites = database.object(forKey: databaseKey) as? [SiteIdentifierType] {
            return sites
        }

        let initializedSites: [SiteIdentifierType]
        // Migrate previously flagged last blog
        if let lastUsedBlog = database.object(forKey: legacyLastUsedBlogKey) as? SiteIdentifierType {
            initializedSites = [lastUsedBlog]
        } else {
            initializedSites = []
        }
        database.set(initializedSites, forKey: databaseKey)
        return initializedSites
    }

    /// Marks a site identifier as recently used. We currently use URL as the identifier.
    ///
    @objc(touchBlogWithIdentifier:)
    func touch(site: SiteIdentifierType) {
        var recent = [site]
        for recentSite in recentSites
            where recentSite != site {
                    recent.append(recentSite)
        }
        database.set(recent, forKey: databaseKey)
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: RecentSitesService.WPTouchedBlogNotification), object: nil)
    }

    /// Marks a Blog as recently used.
    ///
    @objc(touchBlog:)
    func touch(blog: Blog) {
        guard let url = blog.url else {
            assertionFailure("Tried to mark as used a Blog without URL")
            return
        }
        touch(site: url)
    }
}
