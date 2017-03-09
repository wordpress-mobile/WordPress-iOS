import Foundation

public class RecentSitesService: NSObject {
    // We use the site's URL to identify a site
    public typealias SiteIdentifierType = String

    // MARK: - Internal variables
    private let database: KeyValueDatabase
    private let databaseKey = "RecentSites"
    public let maxSiteCount = 3

    // MARK: - Initialization
    public init(database: KeyValueDatabase) {
        self.database = database
        super.init()
    }

    convenience override init() {
        self.init(database: UserDefaults() as KeyValueDatabase)
    }

    // MARK: - Public accessors

    public var recentSites: [SiteIdentifierType] {
        return database.object(forKey: databaseKey) as? [SiteIdentifierType] ?? []
    }

    public func touch(site: SiteIdentifierType) {
        var recent = [site]
        for recentSite in recentSites
            where recentSite != site
                && recent.count < maxSiteCount {
                    recent.append(recentSite)
        }
        database.set(recent, forKey: databaseKey)
    }
}
