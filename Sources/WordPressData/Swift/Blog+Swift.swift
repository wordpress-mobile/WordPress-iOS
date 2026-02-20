import Foundation
import CoreData
import NSURL_IDN

extension Blog {

    /// Stores the relationship to the `BlockEditorSettings` which is an optional entity that holds settings realated to the BlockEditor. These are features
    /// such as Global Styles and Full Site Editing settings and capabilities.
    ///
    @NSManaged public var blockEditorSettings: BlockEditorSettings?

    @objc
    public func supportsBlockEditorSettings() -> Bool {
        return hasRequiredWordPressVersion("5.8")
    }

    /// Returns the username to use for this site.
    ///
    /// For self-hosted sites, returns the stored `username`. For WordPress.com
    /// or Jetpack-connected sites, returns the account's username.
    @objc public var effectiveUsername: String? {
        if let username {
            return username
        } else if let account, isAccessibleThroughWPCom() {
            return account.username
        } else {
            return nil
        }
    }

    // MARK: - URLs

    /// User-facing display URL with protocol and trailing slash stripped, IDN decoded.
    @objc public var displayURL: String? {
        guard let url else { return nil }
        var result = url.replacingOccurrences(
            of: "^https?://",
            with: "",
            options: [.regularExpression, .caseInsensitive]
        )
        if result.hasSuffix("/") {
            result = String(result.dropLast())
        }
        return NSURL.idnDecodedHostname(result) ?? result
    }

    /// The home URL for the blog. Falls back to ``url``.
    @objc public var homeURL: String? {
        getOptionString(name: "home_url") ?? url
    }

    /// The hostname extracted from the XML-RPC endpoint, used for reachability checks.
    @objc public var hostname: String? {
        var result: String?
        if let xmlrpc {
            result = URL(string: xmlrpc)?.host
        }
        if result == nil, let url {
            result = url.replacingOccurrences(
                of: "^.*://",
                with: "",
                options: [.regularExpression, .caseInsensitive]
            )
        }
        // NSURL doesn't recognize some TLDs like .me and .it, returning
        // a full path. Strip path components to avoid breaking reachability.
        return result?.components(separatedBy: "/").first
    }

    /// The login URL for the blog.
    public var loginURL: URL? {
        let string = getOptionString(name: "login_url") ?? url(withPath: "wp-login.php")
        return string.flatMap(URL.init)
    }

    /// Builds a URL by replacing `xmlrpc.php` in the XML-RPC endpoint with the given path.
    public func url(withPath path: String) -> String? {
        guard let xmlrpc else { return nil }
        return xmlrpc.replacingOccurrences(
            of: "xmlrpc\\.php$",
            with: path,
            options: [.regularExpression, .caseInsensitive]
        )
    }

    /// Builds an admin URL by appending the given path to the admin base URL.
    public func makeAdminURL(path: String? = nil) -> URL? {
        var base = getOptionString(name: "admin_url") ?? url(withPath: "wp-admin/") ?? ""
        if !base.hasSuffix("/") {
            base += "/"
        }
        return URL(string: base + (path ?? ""))
    }

    // MARK: - Time Zone

    /// The blog's time zone derived from blog options.
    ///
    /// Resolution order: `timezone` (name) → `gmt_offset` → `time_zone` (XML-RPC offset) → GMT.
    @objc public var timeZone: TimeZone? {
        let oneHourInSeconds: Double = 3600
        if let name = getOptionString(name: "timezone"), !name.isEmpty,
           let timeZone = TimeZone(identifier: name) {
            return timeZone
        }
        if let gmtOffset = getOptionValue("gmt_offset") as? NSNumber,
           let timeZone = TimeZone(secondsFromGMT: Int(gmtOffset.doubleValue * oneHourInSeconds)) {
            return timeZone
        }
        if let value = getOptionValue("time_zone") {
            let seconds = Int((value as AnyObject).doubleValue * oneHourInSeconds)
            if let timeZone = TimeZone(secondsFromGMT: seconds) {
                return timeZone
            }
        }
        return .gmt
    }

    // MARK: - Post Formats

    /// Returns the display name for a post format slug.
    ///
    /// Falls back to the "standard" format name when the slug is nil, empty,
    /// or not found in the blog's post formats.
    public func postFormatText(fromSlug slug: String?) -> String? {
        let allFormats = postFormats as? [String: String]
        var result = slug
        if let slug, let name = allFormats?[slug] {
            result = name
        }
        if (result ?? "").isEmpty, let standard = allFormats?[PostFormatStandard] {
            result = standard
        }
        return result
    }

    // MARK: - Privacy / Visibility

    /// Whether the blog is private.
    @objc public var isPrivate: Bool {
        siteVisibility == .private
    }

    @objc public var siteVisibility: SiteVisibility {
        get {
            guard let rawValue = settings?.privacy?.intValue,
                  let visibility = SiteVisibility(rawValue: rawValue) else {
                return .unknown
            }
            return visibility
        }
        set {
            settings?.privacy = NSNumber(value: newValue.rawValue)
        }
    }
}
