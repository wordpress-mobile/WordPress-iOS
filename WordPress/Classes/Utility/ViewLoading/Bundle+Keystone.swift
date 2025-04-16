import Foundation

extension Bundle {
    static var keystone: Bundle {
        Bundle(for: BundleToken.self)
    }
}

private final class BundleToken {}
