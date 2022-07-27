/// A reference to a site that uses the Jetpack API.
///
/// This type contains the site ID and account username as the minimum way to
/// uniquely identify a site and obtain API credentials for it.
///
/// - Warning: this does not contemplate WordPress.com accounts changing
/// usernames, which is a real possibility, but neither does the rest of the app.
/// The keychain will store the oAuth token associated to the username, and if
/// that changes, authentication will stop working.
///
struct JetpackSiteRef: Hashable, Codable {
    /// The WordPress.com site ID.
    let siteID: Int
    /// The WordPress.com username.
    let username: String
    /// The homeURL string  for a site.
    let homeURL: String

    private var hasBackup = false
    private var hasPaidPlan = false

    // Self Hosted Non Jetpack Support
    // Ideally this would be a different "ref" object but the JetpackSiteRef
    // is so coupled into the plugin management that the amount of changes and work needed to change
    // would be very large. This is a workaround for that.
    let isSelfHostedWithoutJetpack: Bool

    /// The XMLRPC path for the site, only applies to self hosted sites with no Jetpack connected
    var xmlRPC: String? = nil

    init?(blog: Blog) {

        // Init for self hosted and no Jetpack
        if blog.account == nil, !blog.isHostedAtWPcom {
            guard
                let username = blog.username,
                let homeURL = blog.homeURL as String?,
                let xmlRPC = blog.xmlrpc
            else {
                return nil
            }

            self.isSelfHostedWithoutJetpack = true
            self.username = username
            self.siteID = Constants.selfHostedSiteID
            self.homeURL = homeURL
            self.xmlRPC = xmlRPC
        }

        // Init for normal Jetpack connected sites
        else {
            guard
                let username = blog.account?.username,
                let siteID = blog.dotComID as? Int,
                let homeURL = blog.homeURL as String?
            else {
                return nil
            }

            self.isSelfHostedWithoutJetpack = false
            self.siteID = siteID
            self.username = username
            self.homeURL = homeURL
            self.hasBackup = blog.isBackupsAllowed()
            self.hasPaidPlan = blog.hasPaidPlan
        }
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine("\(username)-\(siteID)")
    }

    static func ==(lhs: JetpackSiteRef, rhs: JetpackSiteRef) -> Bool {
        return lhs.siteID == rhs.siteID
            && lhs.username == rhs.username
            && lhs.homeURL == rhs.homeURL
            && lhs.hasBackup == rhs.hasBackup
            && lhs.hasPaidPlan == rhs.hasPaidPlan
    }

    func shouldShowActivityLogFilter() -> Bool {
        hasBackup || hasPaidPlan
    }

    struct Constants {
        static let selfHostedSiteID = -1
    }
}
