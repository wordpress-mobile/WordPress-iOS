import Foundation
import CoreData
import ObjectiveC
import NSURL_IDN
import WordPressShared

private nonisolated(unsafe) var blogKeychainKey: UInt8 = 0

extension Blog {

    // MARK: - Core Data Accessors

    @objc public var xmlrpc: String? {
        get {
            willAccessValue(forKey: "xmlrpc")
            let value = primitiveValue(forKey: "xmlrpc") as? String
            didAccessValue(forKey: "xmlrpc")
            return value
        }
        set {
            willChangeValue(forKey: "xmlrpc")
            setPrimitiveValue(newValue, forKey: "xmlrpc")
            didChangeValue(forKey: "xmlrpc")
            // Reset the API client so next time we use the new XML-RPC URL
            xmlrpcApi = nil
        }
    }

    /// WordPress.com site ID. Backed by the `blogID` Core Data attribute.
    @objc public var dotComID: NSNumber? {
        get {
            willAccessValue(forKey: "blogID")
            var value = primitiveValue(forKey: "blogID") as? NSNumber
            if (value?.intValue ?? 0) == 0 {
                value = jetpack?.siteID
                if let value, value.intValue > 0 {
                    self.dotComID = value
                }
            }
            didAccessValue(forKey: "blogID")
            return value
        }
        set {
            willChangeValue(forKey: "blogID")
            setPrimitiveValue(newValue, forKey: "blogID")
            didChangeValue(forKey: "blogID")
        }
    }

    @objc class var keyPathsForValuesAffectingJetpack: Set<String> {
        ["options"]
    }

    // MARK: - Keychain

    /// Injectable keychain for testability.
    var keychain: any KeychainAccessible {
        get {
            objc_getAssociatedObject(self, &blogKeychainKey) as? (any KeychainAccessible) ?? KeychainUtils()
        }
        set {
            objc_setAssociatedObject(self, &blogKeychainKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    @objc public var password: String? {
        get {
            guard let username, !username.isEmpty,
                  let xmlrpc, !xmlrpc.isEmpty else {
                return nil
            }
            if let password = try? keychain.getPassword(for: username, serviceName: xmlrpc) {
                return password
            }
            // Application password can also be used to authenticate XML-RPC.
            return try? getApplicationToken(using: keychain)
        }
        set {
            assert(username != nil, "Can't set password if we don't know the username yet")
            assert(xmlrpc != nil, "Can't set password if we don't know the XML-RPC endpoint yet")
            guard let username, let xmlrpc else { return }
            try? keychain.setPassword(for: username, to: newValue, serviceName: xmlrpc)
        }
    }

    /// Stores the relationship to the `BlockEditorSettings` which is an optional entity that holds settings realated to the BlockEditor. These are features
    /// such as Global Styles and Full Site Editing settings and capabilities.
    ///
    @NSManaged public var blockEditorSettings: BlockEditorSettings?

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

    @objc public var iconURL: URL? {
        guard let icon, !icon.isEmpty else {
            return nil
        }
        return URL(string: icon)
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

    // MARK: - Auth

    @objc public var isBasicAuthCredentialStored: Bool {
        let storage = URLCredentialStorage.shared
        guard let url = self.url.flatMap(URL.init(string:)) else { return false }
        for protectionSpace in storage.allCredentials.keys {
            if protectionSpace.host == url.host
                && protectionSpace.port == (url.port ?? 80)
                && protectionSpace.authenticationMethod == NSURLAuthenticationMethodHTTPBasic {
                return true
            }
        }
        return false
    }

    // MARK: - Logging

    @objc public var logDescription: String {
        let extra: String
        if let account {
            extra = " wp.com account: \(account.username) blogId: \(dotComID?.intValue ?? 0) plan: \(planTitle ?? "") (\(planID?.intValue ?? 0))"
        } else if let jetpack {
            extra = " jetpack: \(jetpack)"
        } else {
            extra = ""
        }
        return "<Blog Name: \(settings?.name ?? "") URL: \(url ?? "") XML-RPC: \(xmlrpc ?? "")\(extra) ObjectID: \(objectID.uriRepresentation())>"
    }

    // MARK: - Misc

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
        if (result ?? "").isEmpty, let standard = allFormats?[Self.postFormatStandard] {
            result = standard
        }
        return result
    }

    /// The WordPress version string derived from the `software_version` blog option.
    @objc public var version: String {
        let value = getOptionValue("software_version")
        if let string = value as? String {
            return string
        }
        if let number = value as? NSNumber {
            return number.stringValue
        }
        return ""
    }

    /// Whether the blog has a mapped domain (different from the default WordPress.com URL).
    @objc public var hasMappedDomain: Bool {
        guard isHostedAtWPcom else { return false }
        let unmappedURL = getOptionString(name: "unmapped_url").flatMap(URL.init)
        let homeURL = homeURL.flatMap(URL.init)
        return unmappedURL?.host != homeURL?.host
    }

    /// The blog's categories sorted alphabetically by name (case-insensitive).
    @objc public var sortedCategories: [PostCategory] {
        (categories ?? []).sorted {
            $0.categoryName.caseInsensitiveCompare($1.categoryName) == .orderedAscending
        }
    }

    /// The set of allowed file types for uploads, derived from blog options.
    public var allowedFileTypes: Set<String> {
        Set(getOptionValue("allowed_file_types") as? [String] ?? [])
    }

    // MARK: - Privacy / Visibility

    /// Whether the blog is private.
    @objc public var isPrivate: Bool {
        siteVisibility == .private
    }

    public var siteVisibility: SiteVisibility {
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
