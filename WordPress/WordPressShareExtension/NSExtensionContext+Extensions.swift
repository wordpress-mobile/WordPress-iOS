import Foundation

/// Encapsulates NSExtensionContext Helper Methods.
///
extension NSExtensionContext {

    func loadWebsiteUrl(completion: (NSURL? -> Void)) {
        let publicUrlIdentifier = "public.url"

        guard let item = inputItems.first as? NSExtensionItem,
            let itemProviders = item.attachments as? [NSItemProvider] else
        {
            completion(nil)
            return
        }

        let urlItemProviders = itemProviders.filter { (itemProvider) in
            return itemProvider.hasItemConformingToTypeIdentifier(publicUrlIdentifier)
        }

        guard let urlItemProvider = urlItemProviders.first else {
            completion(nil)
            return
        }

        urlItemProvider.loadItemForTypeIdentifier(publicUrlIdentifier, options: nil) { (url, error) in
            guard let theURL = url as? NSURL else {
                completion(nil)
                return
            }

            completion(theURL)
        }
    }
}
