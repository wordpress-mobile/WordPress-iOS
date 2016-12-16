import Foundation
import XCTest
@testable import WordPress

class SiteManagementServiceRemoteTests : XCTestCase
{
    let mockRemoteApi = MockWordPressComRestApi()
    var siteManagementServiceRemote: SiteManagementServiceRemote?

    let siteID = NSNumber(value: 999999)

    override func setUp() {
        super.setUp()
        siteManagementServiceRemote = SiteManagementServiceRemote(wordPressComRestApi: mockRemoteApi)
    }

    func testDeleteSiteUsesTheCorrectPath() {
        siteManagementServiceRemote?.deleteSite(siteID, success: nil, failure: nil)

        XCTAssertTrue(mockRemoteApi.postMethodCalled, "Method was not called")
        XCTAssertEqual(mockRemoteApi.URLStringPassedIn!, "v1.1/sites/\(siteID)/delete", "Incorrect URL passed in")
    }

    func testDeleteSiteCallsFailureBlockOnNetworkingFailure() {
        var failureBlockCalled = false

        siteManagementServiceRemote?.deleteSite(siteID,
            success: nil,
            failure: { error in
                failureBlockCalled = true
            })
        mockRemoteApi.failureBlockPassedIn?(NSError(domain:"UnitTest", code:0, userInfo:nil), nil)

        XCTAssertTrue(mockRemoteApi.postMethodCalled, "Method was not called")
        XCTAssertTrue(failureBlockCalled, "Failure block not called")
    }

    func testDeleteSiteCallsFailureBlockWithInvalidResponse() {
        var failureBlockCalled = false
        var failureError: NSError?
        let response = ["invalid", "response"]
        let responseError = SiteManagementServiceRemote.SiteError.deleteInvalidResponse

        siteManagementServiceRemote?.deleteSite(siteID,
            success: nil,
            failure: { error in
                failureBlockCalled = true
                failureError = error
        })
        mockRemoteApi.successBlockPassedIn?(response as AnyObject, HTTPURLResponse())

        XCTAssertTrue(mockRemoteApi.postMethodCalled, "Method was not called")
        XCTAssertTrue(failureBlockCalled, "Failure block not called")
        XCTAssertEqual(failureError?.code, responseError._code, "Incorrect error in failure block")
    }

    func testDeleteSiteCallsFailureBlockWithMissingStatus() {
        var failureBlockCalled = false
        var failureError: NSError?
        let response = ["key1": "value1", "key2": "value2"]
        let responseError = SiteManagementServiceRemote.SiteError.deleteMissingStatus

        siteManagementServiceRemote?.deleteSite(siteID,
            success: nil,
            failure: { error in
                failureBlockCalled = true
                failureError = error
        })
        mockRemoteApi.successBlockPassedIn?(response as AnyObject, HTTPURLResponse())

        XCTAssertTrue(mockRemoteApi.postMethodCalled, "Method was not called")
        XCTAssertTrue(failureBlockCalled, "Failure block not called")
        XCTAssertEqual(failureError?.code, responseError._code, "Incorrect error in failure block")
    }

    func testDeleteSiteCallsFailureBlockWithNotDeleted() {
        var failureBlockCalled = false
        var failureError: NSError?
        let response = ["status": "not-deleted"]
        let responseError = SiteManagementServiceRemote.SiteError.deleteFailed

        siteManagementServiceRemote?.deleteSite(siteID,
            success: nil,
            failure: { error in
                failureBlockCalled = true
                failureError = error
        })
        mockRemoteApi.successBlockPassedIn?(response as AnyObject, HTTPURLResponse())

        XCTAssertTrue(mockRemoteApi.postMethodCalled, "Method was not called")
        XCTAssertTrue(failureBlockCalled, "Failure block not called")
        XCTAssertEqual(failureError?.code, responseError._code, "Incorrect error in failure block")
    }

    func testDeleteSiteCallsSuccessBlock() {
        let response = ["status": "deleted"]
        var successBlockCalled = false

        siteManagementServiceRemote?.deleteSite(siteID,
            success: { () -> Void in
                successBlockCalled = true
            }, failure: nil)
        mockRemoteApi.successBlockPassedIn?(response as AnyObject, HTTPURLResponse())

        XCTAssertTrue(mockRemoteApi.postMethodCalled, "Method was not called")
        XCTAssertTrue(successBlockCalled, "Success block not called")
    }

    func testExportContentUsesTheCorrectPath() {
        siteManagementServiceRemote?.exportContent(siteID, success: nil, failure: nil)

        XCTAssertTrue(mockRemoteApi.postMethodCalled, "Method was not called")
        XCTAssertEqual(mockRemoteApi.URLStringPassedIn!, "v1.1/sites/\(siteID)/exports/start", "Incorrect URL passed in")
    }

    func testExportContentCallsFailureBlockOnNetworkingFailure() {
        var failureBlockCalled = false

        siteManagementServiceRemote?.exportContent(siteID,
            success: nil,
            failure: { error in
                failureBlockCalled = true
        })
        mockRemoteApi.failureBlockPassedIn?(NSError(domain:"UnitTest", code:0, userInfo:nil), HTTPURLResponse())

        XCTAssertTrue(mockRemoteApi.postMethodCalled, "Method was not called")
        XCTAssertTrue(failureBlockCalled, "Failure block not called")
    }

    func testExportContentCallsFailureBlockWithInvalidResponse() {
        var failureBlockCalled = false
        var failureError: NSError?
        let response = ["invalid", "response"]
        let responseError = SiteManagementServiceRemote.SiteError.exportInvalidResponse

        siteManagementServiceRemote?.exportContent(siteID,
            success: nil,
            failure: { error in
                failureBlockCalled = true
                failureError = error
        })
        mockRemoteApi.successBlockPassedIn?(response as AnyObject, HTTPURLResponse())

        XCTAssertTrue(mockRemoteApi.postMethodCalled, "Method was not called")
        XCTAssertTrue(failureBlockCalled, "Failure block not called")
        XCTAssertEqual(failureError?.code, responseError._code, "Incorrect error in failure block")
    }

    func testExportContentCallsFailureBlockWithMissingStatus() {
        var failureBlockCalled = false
        var failureError: NSError?
        let response = ["key1": "value1", "key2": "value2"]
        let responseError = SiteManagementServiceRemote.SiteError.exportMissingStatus

        siteManagementServiceRemote?.exportContent(siteID,
            success: nil,
            failure: { error in
                failureBlockCalled = true
                failureError = error
        })
        mockRemoteApi.successBlockPassedIn?(response as AnyObject, HTTPURLResponse())

        XCTAssertTrue(mockRemoteApi.postMethodCalled, "Method was not called")
        XCTAssertTrue(failureBlockCalled, "Failure block not called")
        XCTAssertEqual(failureError?.code, responseError._code, "Incorrect error in failure block")
    }

    func testExportContentCallsFailureBlockWithNotRunning() {
        var failureBlockCalled = false
        var failureError: NSError?
        let response = ["status": "not-running"]
        let responseError = SiteManagementServiceRemote.SiteError.exportFailed

        siteManagementServiceRemote?.exportContent(siteID,
            success: nil,
            failure: { error in
                failureBlockCalled = true
                failureError = error
        })
        mockRemoteApi.successBlockPassedIn?(response as AnyObject, HTTPURLResponse())

        XCTAssertTrue(mockRemoteApi.postMethodCalled, "Method was not called")
        XCTAssertTrue(failureBlockCalled, "Failure block not called")
        XCTAssertEqual(failureError?.code, responseError._code, "Incorrect error in failure block")
    }

    func testExportContentCallsSuccessBlock() {
        let response = ["status": "running"]
        var successBlockCalled = false

        siteManagementServiceRemote?.exportContent(siteID,
            success: { () -> Void in
                successBlockCalled = true
            }, failure: nil)
        mockRemoteApi.successBlockPassedIn?(response as AnyObject, HTTPURLResponse())

        XCTAssertTrue(mockRemoteApi.postMethodCalled, "Method was not called")
        XCTAssertTrue(successBlockCalled, "Success block not called")
    }

    func testGetActivePurchasesUsesTheCorrectPath() {
        siteManagementServiceRemote?.getActivePurchases(siteID, success: nil, failure: nil)

        XCTAssertTrue(mockRemoteApi.getMethodCalled, "Method was not called")
        XCTAssertEqual(mockRemoteApi.URLStringPassedIn!, "v1.1/sites/\(siteID)/purchases", "Incorrect URL passed in")
    }

    func testGetActivePurchasesCallsFailureBlockOnNetworkingFailure() {
        var failureBlockCalled = false

        siteManagementServiceRemote?.getActivePurchases(siteID,
            success: nil,
            failure: { error in
                failureBlockCalled = true
        })
        mockRemoteApi.failureBlockPassedIn?(NSError(domain:"UnitTest", code:0, userInfo:nil), HTTPURLResponse())

        XCTAssertTrue(mockRemoteApi.getMethodCalled, "Method was not called")
        XCTAssertTrue(failureBlockCalled, "Failure block not called")
    }

    func testGetActivePurchasesCallsFailureBlockWithInvalidResponse() {
        var failureBlockCalled = false
        var failureError: NSError?
        let response = ["invalid", "response"]
        let responseError = SiteManagementServiceRemote.SiteError.purchasesInvalidResponse

        siteManagementServiceRemote?.getActivePurchases(siteID,
            success: nil,
            failure: { error in
                failureBlockCalled = true
                failureError = error
        })
        mockRemoteApi.successBlockPassedIn?(response as AnyObject, HTTPURLResponse())

        XCTAssertTrue(mockRemoteApi.getMethodCalled, "Method was not called")
        XCTAssertTrue(failureBlockCalled, "Failure block not called")
        XCTAssertEqual(failureError?.code, responseError._code, "Incorrect error in failure block")
    }

    func testGetActivePurchasesCallsSuccessBlockWithActives() {
        let response = [["active": 1], ["active": "true"], ["active": "1"]]
        var successBlockCalled = false
        var purchasesCount = 0

        siteManagementServiceRemote?.getActivePurchases(siteID,
            success: { purchases in
                successBlockCalled = true
                purchasesCount = purchases.count
            }, failure: nil)
        mockRemoteApi.successBlockPassedIn?(response as AnyObject, HTTPURLResponse())

        XCTAssertTrue(mockRemoteApi.getMethodCalled, "Method was not called")
        XCTAssertTrue(successBlockCalled, "Success block not called")
        XCTAssertTrue(purchasesCount == 3, "Active purchases not detected")
    }

    func testGetActivePurchasesCallsSuccessBlockWithoutInactives() {
        let response = [["active": 0], ["active": "false"], ["active": "0"]]
        var successBlockCalled = false
        var purchasesCount = 0

        siteManagementServiceRemote?.getActivePurchases(siteID,
            success: { purchases in
                successBlockCalled = true
                purchasesCount = purchases.count
            }, failure: nil)
        mockRemoteApi.successBlockPassedIn?(response as AnyObject, HTTPURLResponse())

        XCTAssertTrue(mockRemoteApi.getMethodCalled, "Method was not called")
        XCTAssertTrue(successBlockCalled, "Success block not called")
        XCTAssertTrue(purchasesCount == 0, "Inactive purchases considered active")
    }

    func testSiteManagementErrorConversion() {
        let errors: [SiteManagementServiceRemote.SiteError] = [.deleteInvalidResponse, .deleteMissingStatus, .deleteFailed, .exportInvalidResponse, .exportMissingStatus, .exportFailed, .purchasesInvalidResponse]
        for error in errors {
            XCTAssertEqual(error.toNSError().localizedDescription, error.description, "Incorrect description provided")
        }
    }
}
