import Foundation


extension OHHTTPStubs
{
    public static func stubRequestsWithPath(path: String, responseJsonEncodedFile: String) {
        let contentTypeJson = "application/json"
        
        OHHTTPStubs.shouldStubRequestsPassingTest({ (request: NSURLRequest!) -> Bool in
                let range = request.URL?.absoluteString.rangeOfString(path)
                return range != nil
            
            },
            withStubResponse: { (request: NSURLRequest!) -> OHHTTPStubsResponse! in
                return OHHTTPStubsResponse(file: responseJsonEncodedFile,
                                    contentType: contentTypeJson,
                                   responseTime: OHHTTPStubsDownloadSpeedWifi)
        })
    }
}
