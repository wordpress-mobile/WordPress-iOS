import Foundation
import XCTest
@testable import WordPress

class SiteManagementServiceTests: XCTestCase {
    var contextManager: TestContextManager!
    var mockRemoteService: MockSiteManagementServiceRemote!
    var siteManagementService: SiteManagementServiceTester!

    class MockSiteManagementServiceRemote: SiteManagementServiceRemote {
        var deleteSiteCalled = false
        var exportContentCalled = false
        var getActivePurchasesCalled = false
        var successBlockPassedIn: (() -> Void)?
        var successResultBlockPassedIn: (([SitePurchase]) -> Void)?
        var failureBlockPassedIn: ((NSError) -> Void)?

        override func deleteSite(_ siteID: NSNumber, success: (() -> Void)?, failure: ((NSError) -> Void)?) {
            deleteSiteCalled = true
            successBlockPassedIn = success
            failureBlockPassedIn = failure
        }

        override func exportContent(_ siteID: NSNumber, success: (() -> Void)?, failure: ((NSError) -> Void)?) {
            exportContentCalled = true
            successBlockPassedIn = success
            failureBlockPassedIn = failure
        }

        override func getActivePurchases(_ siteID: NSNumber, success: (([SitePurchase]) -> Void)?, failure: ((NSError) -> Void)?) {
            getActivePurchasesCalled = true
            failureBlockPassedIn = failure
            successResultBlockPassedIn = success
        }

        func reset() {
            deleteSiteCalled = false
            exportContentCalled = false
            getActivePurchasesCalled = false
            successBlockPassedIn = nil
            successResultBlockPassedIn = nil
            failureBlockPassedIn = nil
        }
    }

    class SiteManagementServiceTester: SiteManagementService {
        let mockRemoteApi = MockWordPressComRestApi()
        lazy var mockRemoteService: MockSiteManagementServiceRemote = {
            return MockSiteManagementServiceRemote(wordPressComRestApi: self.mockRemoteApi)
        }()

        override func siteManagementServiceRemoteForBlog(_ blog: Blog) -> SiteManagementServiceRemote {
            return mockRemoteService
        }
    }

    override func setUp() {
        super.setUp()

        contextManager = TestContextManager()
        siteManagementService = SiteManagementServiceTester(managedObjectContext: contextManager.mainContext)
        mockRemoteService = siteManagementService.mockRemoteService
    }

    override func tearDown() {
        super.tearDown()
        ContextManager.overrideSharedInstance(nil)
    }

    func insertBlog(_ context: NSManagedObjectContext) -> Blog {
        let blog = NSEntityDescription.insertNewObject(forEntityName: "Blog", into: context) as! Blog
        blog.xmlrpc = "http://mock.blog/xmlrpc.php"
        blog.url = "http://mock.blog/"
        blog.dotComID = 999999

        try! context.obtainPermanentIDs(for: [blog])
        try! context.save()

        return blog
    }

    func testDeleteSiteCallsServiceRemoteDeleteSite() {
        let context = contextManager.mainContext
        let blog = insertBlog(context)

        mockRemoteService.reset()
        siteManagementService.deleteSiteForBlog(blog, success: nil, failure: nil)
        XCTAssertTrue(mockRemoteService.deleteSiteCalled, "Remote DeleteSite should have been called")
    }

    func testDeleteSiteCallsSuccessBlock() {
        let context = contextManager.mainContext
        let blog = insertBlog(context)

        let expect = expectation(description: "Delete Site success expectation")
        mockRemoteService.reset()
        siteManagementService.deleteSiteForBlog(blog,
            success: {
                expect.fulfill()
            }, failure: nil)
        mockRemoteService.successBlockPassedIn?()
        waitForExpectations(timeout: 2, handler: nil)
    }

    func testDeleteSiteRemovesExistingBlogOnSuccess() {
        let context = contextManager.mainContext
        let blog =


            insertBlog(context)
        let blogObjectID = blog.objectID

        XCTAssertFalse(blogObjectID.isTemporaryID, "Should be a permanent object")

        let expect = expectation(
            description: "Remove Blog success expectation")
        mockRemoteService.reset()
        siteManagementService.deleteSiteForBlog(blog,
            success: {
                expect.fulfill()
            }, failure: nil)
        mockRemoteService.successBlockPassedIn?()
        waitForExpectations(timeout: 2, handler: nil)

        let shouldBeRemoved = try? context.existingObject(with: blogObjectID)
        XCTAssertFalse(shouldBeRemoved != nil, "Blog was not removed")
    }

    func testDeleteSiteCallsFailureBlock() {
        let context = contextManager.mainContext
        let blog = insertBlog(context)

        let testError = NSError(domain: "UnitTest", code: 0, userInfo: nil)
        let expect = expectation(description: "Delete Site failure expectation")
        mockRemoteService.reset()
        siteManagementService.deleteSiteForBlog(blog,
            success: nil,
            failure: { error in
                XCTAssertEqual(error, testError, "Error not propagated")
                expect.fulfill()
            })
        mockRemoteService.failureBlockPassedIn?(testError)
        waitForExpectations(timeout: 2, handler: nil)
    }

    func testDeleteSiteDoesNotRemoveExistingBlogOnFailure() {
        let context = contextManager.mainContext
        let blog = insertBlog(context)
        let blogObjectID = blog.objectID

        XCTAssertFalse(blogObjectID.isTemporaryID, "Should be a permanent object")

        let testError = NSError(domain: "UnitTest", code: 0, userInfo: nil)
        let expect = expectation(description: "Remove Blog success expectation")
        mockRemoteService.reset()
        siteManagementService.deleteSiteForBlog(blog,
            success: nil,
            failure: { error in
                XCTAssertEqual(error, testError, "Error not propagated")
                expect.fulfill()
            })
        mockRemoteService.failureBlockPassedIn?(testError)
        waitForExpectations(timeout: 2, handler: nil)

        let shouldNotBeRemoved = try? context.existingObject(with: blogObjectID)
        XCTAssertFalse(shouldNotBeRemoved == nil, "Blog was removed")
    }

    func testExportContentCallsServiceRemoteExportContent() {
        let context = contextManager.mainContext
        let blog = insertBlog(context)

        mockRemoteService.reset()
        siteManagementService.exportContentForBlog(blog, success: nil, failure: nil)
        XCTAssertTrue(mockRemoteService.exportContentCalled, "Remote ExportContent should have been called")
    }

    func testExportContentCallsSuccessBlock() {
        let context = contextManager.mainContext
        let blog = insertBlog(context)

        let expect = expectation(description: "ExportContent success expectation")
        mockRemoteService.reset()
        siteManagementService.exportContentForBlog(blog,
            success: {
                expect.fulfill()
            }, failure: nil)
        mockRemoteService.successBlockPassedIn?()
        waitForExpectations(timeout: 2, handler: nil)
    }

    func testExportContentCallsFailureBlock() {
        let context = contextManager.mainContext
        let blog = insertBlog(context)

        let testError = NSError(domain: "UnitTest", code: 0, userInfo: nil)
        let expect = expectation(description: "ExportContent failure expectation")
        mockRemoteService.reset()
        siteManagementService.exportContentForBlog(blog,
            success: nil,
            failure: { error in
                XCTAssertEqual(error, testError, "Error not propagated")
                expect.fulfill()
        })
        mockRemoteService.failureBlockPassedIn?(testError)
        waitForExpectations(timeout: 2, handler: nil)
    }

    func testGetActivePurchasesCallsServiceRemoteGetActivePurchases() {
        let context = contextManager.mainContext
        let blog = insertBlog(context)

        mockRemoteService.reset()
        siteManagementService.getActivePurchasesForBlog(blog, success: nil, failure: nil)
        XCTAssertTrue(mockRemoteService.getActivePurchasesCalled, "Remote GetActivePurchases should have been called")
    }

    func testGetActivePurchasesCallsSuccessBlock() {
        let context = contextManager.mainContext
        let blog = insertBlog(context)

        let expect = expectation(description: "GetActivePurchases success expectation")
        mockRemoteService.reset()
        siteManagementService.getActivePurchasesForBlog(blog,
            success: { purchases in
                expect.fulfill()
            }, failure: nil)
        mockRemoteService.successResultBlockPassedIn?([])
        waitForExpectations(timeout: 2, handler: nil)
    }

    func testGetActivePurchasesCallsFailureBlock() {
        let context = contextManager.mainContext
        let blog = insertBlog(context)

        let testError = NSError(domain: "UnitTest", code: 0, userInfo: nil)
        let expect = expectation(description: "GetActivePurchases failure expectation")
        mockRemoteService.reset()
        siteManagementService.getActivePurchasesForBlog(blog,
            success: nil,
            failure: { error in
                XCTAssertEqual(error, testError, "Error not propagated")
                expect.fulfill()
        })
        mockRemoteService.failureBlockPassedIn?(testError)
        waitForExpectations(timeout: 2, handler: nil)
    }
}
