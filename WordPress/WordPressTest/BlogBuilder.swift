import Foundation

@testable import WordPress

/// Creates a Blog
///
/// Defaults to creating a self-hosted blog
final class BlogBuilder {
    private let blog: Blog

    private let context: NSManagedObjectContext

    init(_ context: NSManagedObjectContext) {
        self.context = context

        blog = NSEntityDescription.insertNewObject(forEntityName: Blog.entityName(), into: context) as! Blog

        // Non-null properties in Core Data
        blog.dotComID = NSNumber(value: arc4random_uniform(UInt32.max))
        blog.url = "https://\(blog.dotComID!).example.com"
        blog.xmlrpc = "https://\(blog.dotComID!).example.com/xmlrpc.php"
    }

    func with(atomic: Bool) -> Self {
        return set(blogOption: "is_wpcom_atomic", value: atomic ? 1 : 0)
    }

    func with(isHostedAtWPCom: Bool) -> Self {
        blog.isHostedAtWPcom = isHostedAtWPCom
        return self
    }

    func with(supportsDomains: Bool) -> Self {
        return with(isHostedAtWPCom: supportsDomains)
            .with(isAdmin: supportsDomains)
    }

    func with(planID: Int) -> Self {
        blog.planID = planID as NSNumber
        return self
    }

    func withJetpack(version: String? = nil, username: String? = nil, email: String? = nil) -> Self {
        set(blogOption: "jetpack_client_id", value: 1)
        set(blogOption: "jetpack_version", value: version as Any)
        set(blogOption: "jetpack_user_login", value: username as Any)
        set(blogOption: "jetpack_user_email", value: email as Any)
        return set(blogOption: "is_automated_transfer", value: false)
    }

    func with(wordPressVersion: String) -> Self {
        return set(blogOption: "software_version", value: wordPressVersion)
    }

    func with(username: String) -> Self {
        blog.username = username
        return self
    }

    func with(password: String) -> Self {
        blog.password = password

        return self
    }

    func with(isAdmin: Bool) -> Self {
        blog.isAdmin = isAdmin

        return self
    }

    func with(siteVisibility: SiteVisibility) -> Self {
        blog.siteVisibility = siteVisibility

        return self
    }

    func with(visible: Bool) -> Self {
        blog.visible = visible

        return self
    }

    func withAnAccount(username: String = "test_user") -> Self {
        // Add Account
        let account = NSEntityDescription.insertNewObject(forEntityName: WPAccount.entityName(), into: context) as! WPAccount
        account.displayName = "displayName"
        account.username = username
        blog.account = account

        return self
    }

    func isHostedAtWPcom() -> Self {
        blog.isHostedAtWPcom = true

        return self
    }

    func isNotHostedAtWPcom() -> Self {
        blog.isHostedAtWPcom = false

        return self
    }

    func isBlazeApproved() -> Self {
        blog.isBlazeApproved = true

        return self
    }

    func with(modules: [String]) -> Self {
        set(blogOption: "active_modules", value: modules)
    }

    func with(blogID: Int) -> Self {
        blog.blogID = blogID as NSNumber

        return self
    }

    func with(url: String) -> Self {
        blog.url = url

        return self
    }

    func with(registeredDomainCount: Int) -> Self {
        var domains: [ManagedDomain] = []
        for _ in 0..<registeredDomainCount {
            let domain = NSEntityDescription.insertNewObject(forEntityName: ManagedDomain.entityName(), into: context) as! ManagedDomain
            domain.domainType = .registered
            domains.append(domain)
        }

        blog.domains = Set(domains)
        return self
    }

    func with(hasDomainCredit: Bool) -> Self {
        blog.hasDomainCredit = hasDomainCredit
        return self
    }

    func with(isWPForTeamsSite: Bool) -> Self {
        return set(blogOption: "is_wpforteams_site", value: isWPForTeamsSite)
    }

    @discardableResult
    func build() -> Blog {
        return blog
    }

    @discardableResult
    func set(blogOption key: String, value: Any) -> Self {
        var options = blog.options ?? [AnyHashable: Any]()
        options[key] = [
            "value": value
        ]

        blog.options = options
        return self
    }

    func with(postFormats: [String: String]) -> Self {
        blog.postFormats = postFormats

        return self
    }
}

extension Blog {
    func supportsWPComAPI() {
        guard let context = managedObjectContext else {
            return
        }

        let account = NSEntityDescription.insertNewObject(forEntityName: WPAccount.entityName(), into: context) as! WPAccount
        account.username = "foo"
        account.addBlogsObject(self)
    }
}
