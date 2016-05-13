import Foundation

@objc public class WPComReferrerUtil : NSObject
{

    /// Add the utm_source query string param to a URL string.
    /// If the utm_source already exists the original path is returned.
    ///
    /// - Parameters:
    ///     - path: A URL string. Can be an absolute or relative URL string.
    ///
    /// - Returns: The path with the utm_source appended, or the original path if it already had a utm_source param.
    ///
    class func addUtmSourceToURLPath(path: String) -> String {
        if path.isEmpty || path.containsString(WPComReferrerGaUtmSourceKey) {
            return path
        }

        guard let urlencodedReferrer = WPComReferrerURL.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet()) else {
            return path
        }
        let joiner = path.containsString("?") ? "&" : "?"
        return "\(path)\(joiner)\(WPComReferrerGaUtmSourceKey)=\(urlencodedReferrer)"
    }

}
