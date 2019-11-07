import Foundation
import XCTest
import OHHTTPStubs
import WordPressKit
@testable import WordPress

class DomainsServiceTests: XCTestCase {
    let testSiteID = 12345

    var remote: DomainsServiceRemote!
    var context: NSManagedObjectContext!
    var testBlog: Blog!

    var domainsEndpoint: String { return "sites/\(testSiteID)/domains" }
    let contentTypeJson = "application/json"

    override func setUp() {
        super.setUp()

        let api = WordPressComRestApi(oAuthToken: "")
        remote = DomainsServiceRemote(wordPressComRestApi: api)
        context = TestContextManager().mainContext
        testBlog = makeTestBlog()
    }

    override func tearDown() {
        super.tearDown()

        ContextManager.overrideSharedInstance(nil)
        context.reset()
        OHHTTPStubs.removeAllStubs()
    }

    fileprivate func stubDomainsResponseWithFile(_ filename: String) {
        stub(condition: { request in
            return (request.url!.absoluteString as NSString).contains(self.domainsEndpoint) && request.httpMethod! == "GET"
        }) { _ in
            let stubPath = OHPathForFile(filename, type(of: self))
            return fixture(filePath: stubPath!, headers: ["Content-Type" as NSObject: self.contentTypeJson as AnyObject])
        }
    }

    fileprivate func makeTestBlog() -> Blog {
        let accountService = AccountService(managedObjectContext: context)
        let blogService = BlogService(managedObjectContext: context)
        let account = accountService.createOrUpdateAccount(withUsername: "user", authToken: "token")
        let blog = blogService.createBlog(with: account)
        blog.xmlrpc = "http://dotcom1.wordpress.com/xmlrpc.php"
        blog.url = "http://dotcom1.wordpress.com/"
        blog.dotComID = testSiteID as NSNumber?

        return blog
    }


    fileprivate func findAllDomains() -> [ManagedDomain] {
        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: ManagedDomain.entityName())
        fetch.sortDescriptors = [ NSSortDescriptor(key: ManagedDomain.Attributes.domainName, ascending: true) ]
        fetch.predicate = NSPredicate(format: "%K == %@", ManagedDomain.Relationships.blog, testBlog)

        if let domains = (try? context.fetch(fetch)) as? [ManagedDomain] {
            return domains
        } else {
            XCTFail()
            return []
        }
    }

    fileprivate func fetchDomains() {
        let expect = expectation(description: "Domains fetch complete expectation")
        let service = DomainsService(managedObjectContext: context, remote: remote)
        service.refreshDomainsForSite(testBlog.dotComID!.intValue, completion: { success in
            expect.fulfill()
        })

        waitForExpectations(timeout: 2, handler: nil)
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
        XCTAssert(updatedDomains[0].domainType == .registered, "Expecting domain #1 to be of type Registered")
        XCTAssert(updatedDomains[1].domainType == .wpCom, "Expecting domain #2 to be of type WPCom")
        XCTAssert(updatedDomains[2].domainType == .siteRedirect, "Expecting domain #3 to be of type SiteRedirect")
        XCTAssert(updatedDomains[3].domainType == .mapped, "Expecting domain #4 to be of type Mapped")

        XCTAssert(updatedDomains[0].isPrimary == true, "Expecting domain #1 to be the primary domain")
        XCTAssert(updatedDomains[1].isPrimary == false, "Expecting domain #2 to not be the primary domain")
    }

    func testDomainServiceUpdatesExistingDomains() {
        let existingDomain = NSEntityDescription.insertNewObject(forEntityName: ManagedDomain.entityName(), into: context) as! ManagedDomain
        existingDomain.domainName = "example.com"
        existingDomain.isPrimary = false
        existingDomain.domainType = .wpCom
        existingDomain.blog = testBlog
        try! context.save()

        let domains = findAllDomains()
        XCTAssert(domains.count == 1, "Expecting 1 domain initially")

        stubDomainsResponseWithFile("domain-service-valid-domains.json")
        fetchDomains()

        let updatedDomains = findAllDomains()

        XCTAssert(updatedDomains.count == 2, "Expecting 2 domains to be parsed")
        XCTAssert(updatedDomains[0].domainType == .registered, "Expecting domain #1 to be of type Registered")
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
