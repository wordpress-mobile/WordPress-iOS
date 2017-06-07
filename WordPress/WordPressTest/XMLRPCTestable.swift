@testable import WordPress

enum XMLRPCTestableConstants {
    static let xmlRpcUrl        = "http://test.com/xmlrpc.php"
    static let xmlRpcUserName   = "username"
    static let xmlRpcPassword   = "password"

    static let xmlRpcBadTypeErrorCode  = 401
    static let xmlRpcBadAuthErrorCode  = 403
    static let xmlRpcNotFoundErrorCode = 404
    static let xmlRpcParseErrorCode    = -32700

    static let xmlRpcBadAuthFailureFilename               = "xmlrpc-bad-username-password-error.xml"
    static let xmlRpcMalformedRequestXMLFailureFilename   = "xmlrpc-malformed-request-xml-error.xml"
}

/// Protocol to be used when testing XMLRPC Remotes
///
protocol XMLRPCTestable {
    func getXmlRpcApi() -> WordPressOrgXMLRPCApi
}

extension XMLRPCTestable {
    func getXmlRpcApi() -> WordPressOrgXMLRPCApi {
        return WordPressOrgXMLRPCApi(endpoint: URL(string: XMLRPCTestableConstants.xmlRpcUrl)!, userAgent: nil)
    }
}
