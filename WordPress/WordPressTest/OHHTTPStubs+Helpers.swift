import Foundation


extension OHHTTPStubs
{
    public static func stubRequestsWithPath(path: String, responseJsonEncodedFile: String) {
        let contentTypeJson = "application/json"
        
        OHHTTPStubs.stubRequestsPassingTest({ (request: NSURLRequest) -> Bool in
                let range = request.URL?.absoluteString.rangeOfString(path)
                return range != nil
            
            },
            withStubResponse: { (request: NSURLRequest!) -> OHHTTPStubsResponse in
                return OHHTTPStubsResponse(fileAtPath: responseJsonEncodedFile,
                    statusCode: 200,
                    headers: ["Content-Type": contentTypeJson])
        })
    }
}
