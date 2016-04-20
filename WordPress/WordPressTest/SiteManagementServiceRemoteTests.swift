import Foundation
import XCTest
import AFNetworking
@testable import WordPress

class SiteManagementServiceRemoteTests : XCTestCase
{
    let mockRemoteApi = MockWordPressComApi()
    var siteManagementServiceRemote: SiteManagementServiceRemote?
  
    let siteID = NSNumber(integer: 999999)
    
    override func setUp() {
        super.setUp()
        siteManagementServiceRemote = SiteManagementServiceRemote(api: mockRemoteApi)
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
        mockRemoteApi.failureBlockPassedIn?(AFHTTPRequestOperation(), NSError(domain:"UnitTest", code:0, userInfo:nil))
        
        XCTAssertTrue(mockRemoteApi.postMethodCalled, "Method was not called")
        XCTAssertTrue(failureBlockCalled, "Failure block not called")
    }

    func testDeleteSiteCallsFailureBlockWithInvalidResponse() {
        var failureBlockCalled = false
        var failureError: NSError?
        let response = ["invalid", "response"]
        let responseError = SiteManagementServiceRemote.DeleteError.InvalidResponse
        
        siteManagementServiceRemote?.deleteSite(siteID,
            success: nil,
            failure: { error in
                failureBlockCalled = true
                failureError = error
        })
        mockRemoteApi.successBlockPassedIn?(AFHTTPRequestOperation(), response)
        
        XCTAssertTrue(mockRemoteApi.postMethodCalled, "Method was not called")
        XCTAssertTrue(failureBlockCalled, "Failure block not called")
        XCTAssertEqual(failureError?.code, responseError._code, "Incorrect error in failure block")
    }
    
    func testDeleteSiteCallsFailureBlockWithMissingStatus() {
        var failureBlockCalled = false
        var failureError: NSError?
        let response = ["key1": "value1", "key2": "value2"]
        let responseError = SiteManagementServiceRemote.DeleteError.MissingStatus
        
        siteManagementServiceRemote?.deleteSite(siteID,
            success: nil,
            failure: { error in
                failureBlockCalled = true
                failureError = error
        })
        mockRemoteApi.successBlockPassedIn?(AFHTTPRequestOperation(), response)
        
        XCTAssertTrue(mockRemoteApi.postMethodCalled, "Method was not called")
        XCTAssertTrue(failureBlockCalled, "Failure block not called")
        XCTAssertEqual(failureError?.code, responseError._code, "Incorrect error in failure block")
    }
    
    func testDeleteSiteCallsFailureBlockWithNotDeleted() {
        var failureBlockCalled = false
        var failureError: NSError?
        let response = ["status": "not-deleted"]
        let responseError = SiteManagementServiceRemote.DeleteError.NotDeleted
        
        siteManagementServiceRemote?.deleteSite(siteID,
            success: nil,
            failure: { error in
                failureBlockCalled = true
                failureError = error
        })
        mockRemoteApi.successBlockPassedIn?(AFHTTPRequestOperation(), response)
        
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
        mockRemoteApi.successBlockPassedIn?(AFHTTPRequestOperation(), response)
        
        XCTAssertTrue(mockRemoteApi.postMethodCalled, "Method was not called")
        XCTAssertTrue(successBlockCalled, "Success block not called")
    }
    
    func testDeleteSiteResultErrorConversion() {
        let errors: [SiteManagementServiceRemote.DeleteError] = [.InvalidResponse, .MissingStatus, .NotDeleted]
        for error in errors {
            XCTAssertEqual(error.toNSError().localizedDescription, error.description, "Incorrect description provided")
        }
    }
}
