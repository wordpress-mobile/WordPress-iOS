import Foundation

extension Bundle {
    @objc public class var wordPressData: Bundle {
        Bundle.module
//        Bundle(for: BundleToken.self)
    }
}

private final class BundleToken {}
