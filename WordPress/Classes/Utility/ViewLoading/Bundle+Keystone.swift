import Foundation

extension Bundle {
    @objc public class var keystone: Bundle {
        Bundle(for: BundleToken.self)
    }
}

private final class BundleToken {}
