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
            message = NSLocalizedString("Empty URL", comment:"Message to show to user when he tries to add a self-hosted site that is an empty URL.")
        case .InvalidURL:
            message = NSLocalizedString("Invalid URL, please check if you wrote a valid site address.", comment:"Message to show to user when he tries to add a self-hosted site that isn't a valid URL.")
        case .InvalidScheme:
            message = NSLocalizedString("Invalid URL scheme inserted, only HTTP and HTTPS are supported.", comment:"Message to show to user when he tries to add a self-hosted site that isn't HTTP or HTTPS.")
        case .NotWordPressError:
            message = NSLocalizedString("That doesn't look like a WordPress site.", comment: "Message to show to user when he tries to add a self-hosted site that isn't a WordPress site.")
        case .MobilePluginRedirectedError:
            message = NSLocalizedString("You seem to have installed a mobile plugin from DudaMobile which is preventing the app to connect to your blog", comment:"")
        case .Invalid:
            message = NSLocalizedString("That doesn't look like a WordPress site.", comment: "Message to show to user when he tries to add a self-hosted site that isn't a WordPress site.")
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
            DDLogSwift.logError(error.localizedDescription)
            failure(error: error)
            return
        }
        validateXMLRPCUrl(xmlrpcURL, success: { (xmlrpcURL) in
                success(xmlrpcURL: xmlrpcURL)
            }, failure: { (error) in
                DDLogSwift.logError(error.localizedDescription)
                failure(error: error)
            })
    }

    private func urlForXMLRPCFromUrlString(urlString: String, addXMLRPC: Bool) throws -> NSURL {
        var resultURLString = urlString
        // Is an empty url? Sorry, no psychic powers yet
        resultURLString = urlString.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        if resultURLString.isEmpty {
            throw WordPressOrgXMLRPCValidatorError.EmptyURL.convertToNSError()
        }

        // Check if it's a valid URL
        // Not a valid URL. Could be a bad protocol (htpp://), syntax error (http//), ...
        // See https://github.com/koke/NSURL-Guess for extra help cleaning user typed URLs
        guard let baseURL = NSURL(string:resultURLString) else {
            throw WordPressOrgXMLRPCValidatorError.InvalidURL.convertToNSError()
        }

        // Let's see if a scheme is provided and it's HTTP or HTTPS
        var scheme = baseURL.scheme.lowercaseString
        if scheme.isEmpty {
            resultURLString = "http://\(resultURLString)"
            scheme = "http"
        }

        guard scheme == "http" || scheme == "https" else {
            throw WordPressOrgXMLRPCValidatorError.InvalidScheme.convertToNSError()
        }

        if baseURL.lastPathComponent != "xmlrpc.php" && addXMLRPC {
            // Assume the given url is the home page and XML-RPC sits at /xmlrpc.php
            DDLogSwift.logInfo("Assume the given url is the home page and XML-RPC sits at /xmlrpc.php")
            resultURLString = "\(resultURLString)/xmlrpc.php"
        }

        guard let url = NSURL(string: resultURLString) else {
            throw WordPressOrgXMLRPCValidatorError.Invalid.convertToNSError()
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
                if let finalURL = httpResponse?.URL {
                    success(xmlrpcURL: finalURL)
                } else {
                    failure(error:WordPressOrgXMLRPCValidatorError.Invalid.convertToNSError())
                }
            }, failure: { (error, httpResponse) in
                failure(error: error)
            })
    }
}
