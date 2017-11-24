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
struct JetpackSiteRef: Hashable {
    /// The WordPress.com site ID.
    let siteID: Int
    /// The WordPress.com username.
    let username: String

    init?(blog: Blog) {
        guard let username = blog.account?.username,
            let siteID = blog.dotComID as? Int else {
                return nil
        }
        self.siteID = siteID
        self.username = username
    }

    var hashValue: Int {
        return "\(username)-\(siteID)".hashValue
    }

    static func ==(lhs: JetpackSiteRef, rhs: JetpackSiteRef) -> Bool {
        return lhs.siteID == rhs.siteID
            && lhs.username == rhs.username
    }
}
