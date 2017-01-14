import Foundation

/// Encapsulates NSExtensionContext Helper Methods.
///
extension NSExtensionContext {

    // MARK: - Public

    /// Attempts to load the Website URL, and returns, asynchronously, the result.
    ///
    func loadWebsiteUrl(_ completion: @escaping ((URL?) -> Void)) {
        loadItemOfType(URL.self, identifier: Identifier.PublicURL, completion: completion)
    }

    /// Attempts to load the Image Attachment, and returns, asynchronously, the result.
    ///
    func loadMediaImage(_ completion: @escaping ((UIImage?) -> Void)) {
        loadItemOfType(AnyObject.self, identifier: Identifier.PublicImage) { payload in
            var loadedImage: UIImage?

            switch payload {
            case let url as URL:
                loadedImage = UIImage(contentsOfURL: url)
            case let data as Data:
                loadedImage = UIImage(data: data)
            case let image as UIImage:
                loadedImage = image
            default:
                break
            }

            completion(loadedImage)
        }
    }

    /// Verifies if the Context contains an Image Attachment, or not
    ///
    func containsMediaAttachment() -> Bool {
        return firstItemProviderConformingToTypeIdentifier(Identifier.PublicImage) != nil
    }



    // MARK: - Private

    /// Extension Item Identifiers
    ///
    fileprivate enum Identifier: String {
        case PublicURL      = "public.url"
        case PublicImage    = "public.image"
    }

    /// Loads the First Item with the specified identifier, and returns its value asynchronously on the main thread.
    ///
    fileprivate func loadItemOfType<T>(_ type: T.Type, identifier: Identifier, completion: @escaping ((T?) -> Void)) {
        guard let itemProvider = firstItemProviderConformingToTypeIdentifier(identifier) else {
            completion(nil)
            return
        }

        itemProvider.loadItem(forTypeIdentifier: identifier.rawValue, options: nil) { (item, error) in
            DispatchQueue.main.async {
                let targetItem = item as? T
                completion(targetItem)
            }
        }
    }

    /// Returns the first NSItemProvider available, that matches with a given identifier.
    ///
    fileprivate func firstItemProviderConformingToTypeIdentifier(_ identifier: Identifier) -> NSItemProvider? {
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
