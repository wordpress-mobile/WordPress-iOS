import UIKit

/// Generic type that handles URL Schemes
public protocol URLHandler {
    /// checks if the specified URL can be opened
    func canOpenURL(_ url: URL) -> Bool

#if compiler(>=6)
    /// opens the specified URL
    func open(_ url: URL,
              options: [UIApplication.OpenExternalURLOptionsKey: Any],
              completionHandler completion: (@MainActor @Sendable (Bool) -> Void)?)
#else
    /// opens the specified URL
    func open(_ url: URL,
              options: [UIApplication.OpenExternalURLOptionsKey: Any],
              completionHandler completion: ((Bool) -> Void)?)
#endif
}

/// conforms UIApplication to URLHandler to allow dependency injection
extension UIApplication: URLHandler {}
