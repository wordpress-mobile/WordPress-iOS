import Foundation
import XCTest
import OHHTTPStubs
@testable import WordPress

class DomainsServiceTests : XCTestCase
{
    let testSiteID = 12345

    var remote: DomainsServiceRemote!
    var context: NSManagedObjectContext!
    var testBlog: Blog!

    var domainsEndpoint: String { return "sites/\(testSiteID)/domains" }
    let contentTypeJson = "application/json"

    override func setUp() {
        super.setUp()

        let api = WordPressComApi(OAuthToken: "")
        remote = DomainsServiceRemote(api: api)
        context = TestContextManager().mainContext
        testBlog = makeTestBlog()
    }

    override func tearDown() {
        super.tearDown()

        OHHTTPStubs.removeAllStubs()
    }

    private func stubDomainsResponseWithFile(filename: String) {
        stub({ request in
            return request.URL!.absoluteString.containsString(self.domainsEndpoint) && request.HTTPMethod == "GET"
        }) { _ in
            let stubPath = OHPathForFile(filename, self.dynamicType)
            return fixture(stubPath!, headers: ["Content-Type": self.contentTypeJson])
        }
    }

    private func makeTestBlog() -> Blog {
        let accountService = AccountService(managedObjectContext: context)
        let blogService = BlogService(managedObjectContext: context)
        let account = accountService.createOrUpdateAccountWithUsername("user", authToken: "token")
        let blog = blogService.createBlogWithAccount(account)
        blog.xmlrpc = "http://dotcom1.wordpress.com/xmlrpc.php"
        blog.url = "http://dotcom1.wordpress.com/"
        blog.dotComID = testSiteID

        return blog
    }

    private func findAllDomains() -> [ManagedDomain] {
        let fetch = NSFetchRequest(entityName: ManagedDomain.entityName)
        fetch.sortDescriptors = [ NSSortDescriptor(key: ManagedDomain.Attributes.domainName, ascending: true) ]
        fetch.predicate = NSPredicate(format: "%K == %@", ManagedDomain.Relationships.blog, testBlog)

        if let domains = (try? context.executeFetchRequest(fetch)) as? [ManagedDomain] {
            return domains
        } else {
            XCTFail()
            return []
        }
    }

    private func fetchDomains() {
        let expectation = expectationWithDescription("Domains fetch complete expectation")
        let service = DomainsService(managedObjectContext: context, remote: remote)
        service.refreshDomainsForSite(Int(testBlog.dotComID!), completion: { success in
            expectation.fulfill()
        })

        waitForExpectationsWithTimeout(0.2, handler: nil)
    }

    func testDomainServiceHandlesTwoNewDomains() {
        let domains = findAllDomains()
        XCTAssert(domains.count == 0, "Expecting no domains initially")

        stubDomainsResponseWithFile("domain-service-valid-domains.json")
        fetchDomains()

        let updatedDomains = findAllDomains()
        XCTAssert(updatedDomains.count == 2, "Expecting 2 domains to be parsed")
    }

    func testDomainServiceParsesPrimaryDomain() {
        stubDomainsResponseWithFile("domain-service-valid-domains.json")
        fetchDomains()

        let updatedDomains = findAllDomains()

        XCTAssert(updatedDomains[0].isPrimary == true, "Expecting domain #1 to be the primary domain")
        XCTAssert(updatedDomains[1].isPrimary == false, "Expecting domain #2 to not be the primary domain")
    }

    func testDomainServiceParsesAllDomainTypes() {
        stubDomainsResponseWithFile("domain-service-all-domain-types.json")
        fetchDomains()

        let updatedDomains = findAllDomains()

        // Domains are sorted by domain name, so we know what order to
        // expect the different types from the stub data
        XCTAssert(updatedDomains[0].domainType == .Registered, "Expecting domain #1 to be of type Registered")
        XCTAssert(updatedDomains[1].domainType == .WPCom, "Expecting domain #2 to be of type WPCom")
        XCTAssert(updatedDomains[2].domainType == .SiteRedirect, "Expecting domain #3 to be of type SiteRedirect")
        XCTAssert(updatedDomains[3].domainType == .Mapped, "Expecting domain #4 to be of type Mapped")

        XCTAssert(updatedDomains[0].isPrimary == true, "Expecting domain #1 to be the primary domain")
        XCTAssert(updatedDomains[1].isPrimary == false, "Expecting domain #2 to not be the primary domain")
    }

    func testDomainServiceUpdatesExistingDomains() {
        let existingDomain = NSEntityDescription.insertNewObjectForEntityForName(ManagedDomain.entityName, inManagedObjectContext: context) as! ManagedDomain
        existingDomain.domainName = "example.com"
        existingDomain.isPrimary = false
        existingDomain.domainType = .WPCom
        existingDomain.blog = testBlog
        try! context.save()

        let domains = findAllDomains()
        XCTAssert(domains.count == 1, "Expecting 1 domain initially")

        stubDomainsResponseWithFile("domain-service-valid-domains.json")
        fetchDomains()

        let updatedDomains = findAllDomains()

        XCTAssert(updatedDomains.count == 2, "Expecting 2 domains to be parsed")
        XCTAssert(updatedDomains[0].domainType == .Registered, "Expecting domain #1 to be of type Registered")
        XCTAssert(updatedDomains[0].domainName == "example.com", "Expecting domain #1 to be 'example.com")
        XCTAssert(updatedDomains[0].isPrimary == true, "Expecting domain #1 to be the primary domain")
    }

    func testDomainServiceRemovesOldDomains() {
        stubDomainsResponseWithFile("domain-service-all-domain-types.json")
        fetchDomains()

        let domains = findAllDomains()
        XCTAssert(domains.count == 4, "Expecting 4 domains initially")

        stubDomainsResponseWithFile("domain-service-valid-domains.json")
        fetchDomains()

        let updatedDomains = findAllDomains()

        XCTAssert(updatedDomains.count == 2, "Expecting 2 domains remaining")

        let domainNames = updatedDomains.map { $0.domainName }
        XCTAssert(domainNames.contains("example.com"), "Expecting domain 'example.com' to be present")
        XCTAssert(domainNames.contains("example2.com"), "Expecting domain 'example2.com' to be present")
    }
}
