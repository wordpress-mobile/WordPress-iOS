import Foundation

@objc
public extension NSCharacterSet {
    /// The base character set `urlPathAllowed` allows single apostrophes.  This encoding is a bit more
    /// restrictive and disallows some extra characters as per RFC 3986.
    ///
    @objc(URLPathRFC3986AllowedCharacterSet)
    static var urlPathRFC3986Allowed: CharacterSet {
        CharacterSet.urlPathAllowed.subtracting(CharacterSet(charactersIn: "!'()*"))
    }
}
