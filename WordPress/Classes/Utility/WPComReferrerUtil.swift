import Foundation

@objc public class WPComReferrerUtil : NSObject
{

    class func addUtmSourceToURLPath(path: String) -> String {
        if path.isEmpty {
            return path
        }
        guard let urlencodedReferrer = WPComReferrerURL.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet()) else {
            return path
        }
        let joiner = path.containsString("?") ? "&" : "?"
        return "\(path)\(joiner)\(WPComReferrerGaUtmSourceKey)=\(urlencodedReferrer)"
    }

}
