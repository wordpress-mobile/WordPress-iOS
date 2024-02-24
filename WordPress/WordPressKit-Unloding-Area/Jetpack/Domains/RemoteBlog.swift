import Foundation
import NSObject_SafeExpectations

/// This class encapsulates all of the *remote* Blog properties
@objcMembers public class RemoteBlog: NSObject {

    /// The ID of the Blog entity.
    public var blogID: NSNumber

    /// The organization ID of the Blog entity.
    public var organizationID: NSNumber

    /// Represents the Blog Name.
    public var name: String

    /// Description of the WordPress Blog.
    public var tagline: String?

    /// Represents the Blog Name.
    public var url: String

    /// Maps to the XMLRPC endpoint.
    public var xmlrpc: String?

    /// Site Icon's URL.
    public var icon: String?

    /// Product ID of the site's current plan, if it has one.
    public var planID: NSNumber?

    /// Product name of the site's current plan, if it has one.
    public var planTitle: String?

    /// Indicates whether the current's blog plan is paid, or not.
    public var hasPaidPlan: Bool = false

    /// Features available for the current blog's plan.
    public var planActiveFeatures = [String]()

    /// Indicates whether it's a jetpack site, or not.
    public var jetpack: Bool = false

    /// Boolean indicating whether the current user has Admin privileges, or not.
    public var isAdmin: Bool = false

    /// Blog's visibility preferences.
    public var visible: Bool = false

    /// Blog's options preferences.
    public var options: NSDictionary

    /// Blog's capabilities: Indicate which actions are allowed / not allowed, for the current user.
    public var capabilities: [String: Bool]

    /// Blog's total disk quota space.
    public var quotaSpaceAllowed: NSNumber?

    /// Blog's total disk quota space used.
    public var quotaSpaceUsed: NSNumber?

    /// Parses details from a JSON dictionary, as returned by the WordPress.com REST API.
    @objc(initWithJSONDictionary:)
    public init(jsonDictionary json: NSDictionary) {
        self.blogID = json.number(forKey: "ID") ?? 0
        self.organizationID = json.number(forKey: "organization_id") ?? 0
        self.name = json.string(forKey: "name") ?? ""
        self.tagline = json.string(forKey: "description")
        self.url = json.string(forKey: "URL") ?? ""
        self.xmlrpc = json.string(forKeyPath: "meta.links.xmlrpc")
        self.jetpack = json.number(forKey: "jetpack")?.boolValue ?? false
        self.icon = json.string(forKeyPath: "icon.img")
        self.capabilities = json.object(forKey: "capabilities") as? [String: Bool] ?? [:]
        self.isAdmin = json.number(forKeyPath: "capabilities.manage_options")?.boolValue ?? false
        self.visible = json.number(forKey: "visible")?.boolValue ?? false
        self.options = RemoteBlogOptionsHelper.mapOptions(fromResponse: json)
        self.planID = json.number(forKeyPath: "plan.product_id")
        self.planTitle = json.string(forKeyPath: "plan.product_name_short")
        self.hasPaidPlan = !(json.number(forKeyPath: "plan.is_free")?.boolValue ?? true)
        self.planActiveFeatures = (json.array(forKeyPath: "plan.features.active") as? [String]) ?? []
        self.quotaSpaceAllowed = json.number(forKeyPath: "quota.space_allowed")
        self.quotaSpaceUsed = json.number(forKeyPath: "quota.space_used")
    }

}
