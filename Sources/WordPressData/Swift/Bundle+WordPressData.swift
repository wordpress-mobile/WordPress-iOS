import Foundation

extension Bundle {
    public static var wordPressData: Bundle {
        Bundle(for: BundleToken.self)
    }
}

private final class BundleToken {}
