import Foundation


/// Encapsulates NSURLSessionConfiguration Helpers
///
extension NSURLSessionConfiguration
{
    /// Returns a new Background Session Configuration, with a random identifier.
    ///
    class func backgroundSessionConfigurationWithRandomizedIdentifier() -> NSURLSessionConfiguration {
        let identifier = WPAppGroupName + "." + NSUUID().UUIDString
        let configuration = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier(identifier)
        configuration.sharedContainerIdentifier = WPAppGroupName

        return configuration
    }
}
