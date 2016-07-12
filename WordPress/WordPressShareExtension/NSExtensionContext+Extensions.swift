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
    func loadMediaImage(completion: (UIImage? -> Void)) {
        loadItemOfType(AnyObject.self, identifier: Identifier.PublicImage) { payload in
            var loadedImage: UIImage?

            switch payload {
            case let url as NSURL:
                loadedImage = UIImage(contentsOfURL: url)
            case let data as NSData:
                loadedImage = UIImage(data: data)
            case let image as UIImage:
                loadedImage = image
            default:
                break
            }

            completion(loadedImage)
        }
    }



    // MARK: - Private

    /// Extension Item Identifiers
    ///
    private enum Identifier : String {
        case PublicURL      = "public.url"
        case PublicImage    = "public.image"
    }

    /// Loads the First Item with the specified identifier, and returns its value asynchronously on the main thread.
    ///
    private func loadItemOfType<T>(type: T.Type, identifier: Identifier, completion: (T? -> Void)) {
        guard let itemProvider = firstItemProviderConformingToTypeIdentifier(identifier) else {
            completion(nil)
            return
        }

        itemProvider.loadItemForTypeIdentifier(identifier.rawValue, options: nil) { (item, error) in
            dispatch_async(dispatch_get_main_queue()) {
                let targetItem = item as? T
                completion(targetItem)
            }
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
