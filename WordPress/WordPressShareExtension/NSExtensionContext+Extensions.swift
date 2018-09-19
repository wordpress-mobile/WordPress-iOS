import Foundation

/// Encapsulates NSExtensionContext Helper Methods.
///
extension NSExtensionContext {
    /// Returns all the NSItemProvider attachments on the first NSItemProvider 
    /// that conform to a specific type identifier
    ///
    func itemProviders(ofType type: String) -> [NSItemProvider] {
        guard let item = inputItems.first as? NSExtensionItem,
            let providers = item.attachments else {
            return []
        }
        return providers.filter { provider in
            return provider.hasItemConformingToTypeIdentifier(type)
        }
    }
}
