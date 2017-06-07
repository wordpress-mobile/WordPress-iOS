import Foundation
import XCTest
import OHHTTPStubs
@testable import WordPressKit

/// Base class for all remote unit tests.
///
class RemoteTestCase: XCTestCase {

    /// Response content types
    ///
    enum ResponseContentType: String {
        case ApplicationJSON = "application/json"
        case JavaScript      = "text/javascript;charset=utf-8"
        case ApplicationHTML = "application/html"
        case NoContentType   = ""
    }

    // MARK: - Constants

    let timeout             = TimeInterval(1000)

    // MARK: - Properties

    var restApi: WordPressComRestApi!
//    var testContextManager: TestContextManager!

    // MARK: - Overridden Methods

    override func setUp() {
        super.setUp()
//        testContextManager = TestContextManager()
        restApi = WordPressComRestApi(oAuthToken: nil, userAgent: nil)
        stubAllNetworkRequestsWithNotConnectedError()
    }

    override func tearDown() {
        super.tearDown()

//        ContextManager.overrideSharedInstance(nil)
//        testContextManager.mainContext.reset()
//        testContextManager = nil
        restApi = nil
        OHHTTPStubs.removeAllStubs()
    }
}


// MARK: - Remote testing helpers
//
extension RemoteTestCase {

    /// Helper function that creates a stub which uses a file for the response body.
    ///
    /// - Parameters:
    ///     - endpoint: The endpoint matcher block that determines if the request will be stubbed
    ///     - filename: The name of the file to use for the response
    ///     - contentType: The Content-Type returned in the response header
    ///     - status: The status code to use for the response. Defaults to 200.
    ///
    func stubRemoteResponse(_ endpoint: String, filename: String, contentType: ResponseContentType, status: Int32 = 200) {
        stub(condition: { request in
            return request.url?.absoluteString.range(of: endpoint) != nil
        }) { _ in
            let stubPath = OHPathForFile(filename, type(of: self))
            var headers: Dictionary<NSObject, AnyObject>?

            if contentType != .NoContentType {
                headers = ["Content-Type" as NSObject: contentType.rawValue as AnyObject]
            }
            return fixture(filePath: stubPath!, status: status, headers: headers)
        }
    }

    /// Helper function that creates a stub which uses the provided Data object for the response body.
    ///
    /// - Parameters:
    ///     - endpoint: The endpoint matcher block that determines if the request will be stubbed
    ///     - data: Data object to use for the response
    ///     - contentType: The Content-Type returned in the response header
    ///     - status: The status code to use for the response. Defaults to 200.
    ///
    func stubRemoteResponse(_ endpoint: String, data: Data, contentType: ResponseContentType, status: Int32 = 200) {
        stub(condition: { request in
            return request.url?.absoluteString.range(of: endpoint) != nil
        }) { _ in
            var headers: Dictionary<NSObject, AnyObject>?

            if contentType != .NoContentType {
                headers = ["Content-Type" as NSObject: contentType.rawValue as AnyObject]
            }
            return OHHTTPStubsResponse(data: data, statusCode: status, headers: headers)
        }
    }

    /// Helper function that stubs ALL endpoints so that they return a CFNetworkErrors.cfurlErrorNotConnectedToInternet
    /// error. In the response, prior to returning the error, XCTFail will also be called logging the endpoint
    /// which was called.
    /// 
    /// - Note: Remember that order is important when stubbing requests with OHHTTPStubs. Therefore, it is important
    ///         this is called **before** stubbing out a specific endpoint you are testing. See: 
    ///         https://github.com/AliSoftware/OHHTTPStubs/wiki/Usage-Examples#stack-multiple-stubs-and-remove-installed-stubs
    ///
    func stubAllNetworkRequestsWithNotConnectedError() {
        stub(condition: { request in
            return true
        }) { response in
            XCTFail("Unexpected network request was made to: \(response.url!.absoluteString)")
            let notConnectedError = NSError(domain:NSURLErrorDomain, code:Int(CFNetworkErrors.cfurlErrorNotConnectedToInternet.rawValue), userInfo:nil)
            return OHHTTPStubsResponse(error:notConnectedError)
        }
    }

    /// Helper function that clears any *.json files from the local disk cache. Useful for ensuring a network
    /// call is made instead of a cache hit.
    ///
    func clearDiskCache() {
        let cacheDirectory =  FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first! as NSURL

        do {
            if let documentPath = cacheDirectory.path {
                let fileNames = try FileManager.default.contentsOfDirectory(atPath: "\(documentPath)")
                for fileName in fileNames {
                    if (fileName.hasSuffix(".json")) {
                        print("Removing \(fileName) from cache.")
                        let filePathName = "\(documentPath)/\(fileName)"
                        try FileManager.default.removeItem(atPath: filePathName)
                    }
                }
            }
        } catch {
            print("Unable to clear cache: \(error)")
        }
    }
}
