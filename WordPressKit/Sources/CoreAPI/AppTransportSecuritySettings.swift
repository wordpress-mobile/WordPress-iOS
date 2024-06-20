import Foundation

/// A dependency of `AppTransportSecuritySettings` generally used for injection in unit tests.
///
/// Only `Bundle` would conform to this `protocol`.
protocol InfoDictionaryObjectProvider {
    func object(forInfoDictionaryKey key: String) -> Any?
}

extension Bundle: InfoDictionaryObjectProvider {

}

/// Provides a simpler interface to the `Bundle` (`Info.plist`) settings under the
/// `NSAppTransportSecurity` key.
struct AppTransportSecuritySettings {

    private let infoDictionaryObjectProvider: InfoDictionaryObjectProvider

    private var settings: NSDictionary? {
        infoDictionaryObjectProvider.object(forInfoDictionaryKey: "NSAppTransportSecurity") as? NSDictionary
    }

    private var exceptionDomains: NSDictionary? {
        settings?["NSExceptionDomains"] as? NSDictionary
    }

    init(_ infoDictionaryObjectProvider: InfoDictionaryObjectProvider = Bundle.main) {
        self.infoDictionaryObjectProvider = infoDictionaryObjectProvider
    }

    /// Returns whether the `NSAppTransportSecurity` settings indicate that access to the
    /// given `siteURL` should be through SSL/TLS only.
    ///
    /// Secure access is the default that is set by Apple. But the hosting app is allowed to
    /// override this for specific or for all domains. This method encapsulates the logic for
    /// reading the `Bundle` (`Info.plist`) settings and translating the rules and conditions
    /// described in the
    /// [NSAppTransportSecurity](https://developer.apple.com/documentation/bundleresources/information_property_list/nsapptransportsecurity)
    /// documentation and its sub-pages.
    func secureAccessOnly(for siteURL: URL) -> Bool {
        // From Apple: If you specify an exception domain dictionary, ATS ignores any global
        // configuration keys, like NSAllowsArbitraryLoads, for that domain. This is true even
        // if you leave the domain-specific dictionary empty and rely entirely on its keys’ default
        // values.
        if let exceptionDomain = self.exceptionDomain(for: siteURL) {
            let allowsInsecureHTTPLoads =
                exceptionDomain["NSExceptionAllowsInsecureHTTPLoads"] as? Bool ?? false
            return !allowsInsecureHTTPLoads
        }

        guard let settings = settings else {
            return true
        }

        // From Apple: The value of the `NSAllowsArbitraryLoads` key is ignored—and the default value of
        // NO used instead—if any of the following keys are present:
        guard settings["NSAllowsLocalNetworking"] == nil &&
                settings["NSAllowsArbitraryLoadsForMedia"] == nil &&
                settings["NSAllowsArbitraryLoadsInWebContent"] == nil else {
            return true
        }

        let allowsArbitraryLoads = settings["NSAllowsArbitraryLoads"] as? Bool ?? false
        return !allowsArbitraryLoads
    }

    private func exceptionDomain(for siteURL: URL) -> NSDictionary? {
        guard let domain = siteURL.host?.lowercased() else {
            return nil
        }

        return exceptionDomains?[domain] as? NSDictionary
    }
}
