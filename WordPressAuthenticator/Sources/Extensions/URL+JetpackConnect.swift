import Foundation

extension URL {
    public var isJetpackConnect: Bool {
        query?.contains("&source=jetpack") ?? false
    }
}
