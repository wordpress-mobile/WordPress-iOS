import Foundation

/// Encapsulates NSExtensionContext Helper Methods.
///
extension NSExtensionContext {

    // MARK: - Public

    /// Attempts to load the Website URL, and returns, asynchronously, the result.
    ///
    func loadWebsiteUrl(completion: (NSURL? -> Void)) {
        loadItemOfType(NSURL.self, identifier: Identifier.PublicURL, completion: completion)
    }

    /// Attempts to load the Image Attachment, and returns, asynchronously, the result.
    ///
    func loadImageAttachment(completion: (UIImage? -> Void)) {
        loadItemOfType(NSURL.self, identifier: Identifier.PublicImage) { url in
            guard let targetURL = url, let rawImage = NSData(contentsOfURL: targetURL) else {
                completion(nil)
                return
            }

            let image = UIImage(data: rawImage)
            completion(image)
        }
    }



    // MARK: - Private

    /// Extension Item Identifiers
    ///
    private enum Identifier : String {
        case PublicURL      = "public.url"
        case PublicImage    = "public.image"
    }

    /// Loads the First Item with the specified identifier, and returns its value asynchronously.
    ///
    private func loadItemOfType<T>(type: T.Type, identifier: Identifier, completion: (T? -> Void)) {
        guard let itemProvider = firstItemProviderConformingToTypeIdentifier(identifier) else {
            completion(nil)
            return
        }

        itemProvider.loadItemForTypeIdentifier(identifier.rawValue, options: nil) { (item, error) in
            let targetItem = item as? T
            completion(targetItem)
        }
    }

    /// Returns the first NSItemProvider available, that matches with a given identifier.
    ///
    private func firstItemProviderConformingToTypeIdentifier(identifier: Identifier) -> NSItemProvider? {
        guard let item = inputItems.first as? NSExtensionItem,
            let itemProviders = item.attachments as? [NSItemProvider] else {
            return nil
        }

        let filteredItemProviders = itemProviders.filter { itemProvider in
            return itemProvider.hasItemConformingToTypeIdentifier(identifier.rawValue)
        }

        return filteredItemProviders.first
    }
}
