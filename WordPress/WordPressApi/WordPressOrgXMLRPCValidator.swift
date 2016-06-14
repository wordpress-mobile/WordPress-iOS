import Foundation

@objc public enum WordPressOrgXMLRPCValidatorError: Int, ErrorType {
    case EmptyURL // The URL provided was nil, empty or just whitespaces
    case InvalidURL // The URL provided was an invalid URL
    case InvalidScheme // The URL provided was an invalid scheme, only HTTP and HTTPS supported
    case NotWordPressError // That's a XML-RPC endpoint but doesn't look like WordPress
    case MobilePluginRedirectedError // There's some "mobile" plugin redirecting everything to their site
    case Invalid // Doesn't look to be valid XMLRPC Endpoint.

    func convertToNSError() -> NSError {
        let castedError = self as NSError
        let message: String
        switch (self) {
        case .EmptyURL:
            message = NSLocalizedString("Empty URL", comment:"")
        case .InvalidURL:
            message = NSLocalizedString("Empty URL", comment:"")
        case .InvalidScheme:
            message = NSLocalizedString("Empty URL", comment:"")
        case .NotWordPressError:
            message = NSLocalizedString("That doesn't look like a WordPress site", comment: "User message when he tries to add a self-hosted site that isn't WordPress")
        case .MobilePluginRedirectedError:
            message = NSLocalizedString("Empty URL", comment:"")
        case .Invalid:
            message = NSLocalizedString("Empty URL", comment:"")
        }
        let finalError = NSError(domain: castedError.domain,
                                 code: castedError.code,
                                 userInfo: [NSLocalizedDescriptionKey: message])
        return finalError
    }
}

public class WordPressOrgXMLRPCValidator: NSObject {

    override public init() {
        super.init()
    }

    public func guessXMLRPCURLForSite(site: String,
                                      success: (xmlrpcURL: NSURL) -> (),
                                      failure: (error: NSError) -> ()) {
        let xmlrpcURL: NSURL
        do {
            xmlrpcURL = try urlForXMLRPCFromUrlString(site, addXMLRPC: true)
        } catch let error as NSError {
            failure(error: error)
            return
        }
        success(xmlrpcURL: xmlrpcURL)
    }

    private func urlForXMLRPCFromUrlString(urlString: String, addXMLRPC: Bool) throws -> NSURL {
        var resultURLString = urlString
        // Is an empty url? Sorry, no psychic powers yet
        resultURLString = urlString.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        if resultURLString.isEmpty {
            throw WordPressOrgXMLRPCValidatorError.EmptyURL
        }

        // Check if it's a valid URL
        // Not a valid URL. Could be a bad protocol (htpp://), syntax error (http//), ...
        // See https://github.com/koke/NSURL-Guess for extra help cleaning user typed URLs
        guard let baseURL = NSURL(string:resultURLString) else {
            throw WordPressOrgXMLRPCValidatorError.InvalidURL
        }

        // Let's see if a scheme is provided and it's HTTP or HTTPS
        var scheme = baseURL.scheme.lowercaseString
        if scheme.isEmpty {
            resultURLString = "http://\(resultURLString)"
            scheme = "http"
        }

        guard scheme == "http" || scheme == "https" else {
            throw WordPressOrgXMLRPCValidatorError.InvalidScheme
        }

        if baseURL.lastPathComponent != "xmlrpc.php" && addXMLRPC {
            // Assume the given url is the home page and XML-RPC sits at /xmlrpc.php
            DDLogSwift.logInfo("Assume the given url is the home page and XML-RPC sits at /xmlrpc.php")
            resultURLString = "\(resultURLString)/xmlrpc.php"
        }

        guard let url = NSURL(string: resultURLString) else {
            throw WordPressOrgXMLRPCValidatorError.Invalid
        }

        return url
    }

    private func validateXMLRPCUrl(url:NSURL,
                                   success: (xmlrpcURL: NSURL) -> (),
                                   failure: (error: NSError) -> ()) {
        let api = WordPressOrgXMLRPCApi(endpoint: url)
        api.callMethod("system.listMethods", parameters: nil, success: { (responseObject, httpResponse) in
                guard let methods = responseObject as? [String]
                      where methods.contains("wp.getUsersBlogs") else {
                        failure(error:WordPressOrgXMLRPCValidatorError.NotWordPressError.convertToNSError())
                        return
                }
            success(xmlrpcURL: url)
            }, failure: { (error, httpResponse) in
                failure(error: error)
            })
    }
}
