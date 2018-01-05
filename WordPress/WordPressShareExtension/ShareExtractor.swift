import Foundation
import MobileCoreServices
import UIKit

/// A type that represents the information we can extract from an extension context
///
struct ExtractedShare {
    var title: String
    var description: String
    var url: URL?
    var selectedText: String
    var images: [UIImage]

    var combinedContentFields: String {
        var returnString: String

        if selectedText.isEmpty {
            if description.isEmpty {
                returnString = title
            } else {
                returnString = description
            }
        } else {
            returnString = selectedText
        }

        if let url = url {
            returnString.append("\n\(url.absoluteString)")
        }

        return returnString
    }
}

/// Extracts valid information from an extension context.
///
struct ShareExtractor {
    let extensionContext: NSExtensionContext

    init(extensionContext: NSExtensionContext) {
        self.extensionContext = extensionContext
    }

    /// Loads the content asynchronously.
    ///
    /// - Important: This method will only call completion if it can successfully extract content.
    /// - Parameters:
    ///   - completion: the block to be called when the extractor has obtained content.
    ///
    func loadShare(completion: @escaping (ExtractedShare) -> Void) {
        extractText { extractedTextResults in
            self.extractImages { images in
                let title = extractedTextResults?.title ?? ""
                let description = extractedTextResults?.description ?? ""
                let selectedText = extractedTextResults?.selectedText ?? ""
                let url = extractedTextResults?.url
                let returnedImages = images ?? [UIImage]()

                completion(ExtractedShare(title: title,
                                          description: description,
                                          url: url,
                                          selectedText: selectedText,
                                          images: returnedImages))
            }
        }
    }

    /// Determines if the extractor will be able to obtain valid content from
    /// the extension context.
    ///
    /// This doesn't ensure success though. It will only check that the context
    /// includes known types, but there might still be errors loading the content.
    ///
    var validContent: Bool {
        return textExtractor != nil || imageExtractor != nil
    }
}


// MARK: - Private

/// A private type that represents the information we can extract from an extension context
/// attachment
///
private struct ExtractedItem {
    /// Any text that was selected
    ///
    var selectedText: String?

    /// A description of the resource if available
    ///
    var description: String?

    /// A URL associated with the resource if available
    ///
    var url: URL?

    /// A title of the resource if available
    ///
    var title: String?

    /// An image
    ///
    var image: UIImage?
}

private extension ShareExtractor {
    var supportedTextExtractors: [ExtensionContentExtractor] {
        return [
            SharePostExtractor(),
            PropertyListExtractor(),
            URLExtractor(),
            PlainTextExtractor()
        ]
    }

    var imageExtractor: ExtensionContentExtractor? {
        return ImageExtractor()
    }

    var textExtractor: ExtensionContentExtractor? {
        return supportedTextExtractors.first(where: { extractor in
            extractor.canHandle(context: extensionContext)
        })
    }

    func extractText(completion: @escaping (ExtractedItem?) -> Void) {
        guard let textExtractor = textExtractor else {
            completion(nil)
            return
        }
        textExtractor.extract(context: extensionContext) { extractedItems in
            guard extractedItems.count > 0 else {
                completion(nil)
                return
            }
            let combinedTitle = extractedItems.flatMap({ $0.title }).joined(separator: " ")
            let combinedDescription = extractedItems.flatMap({ $0.description }).joined(separator: " ")
            let combinedSelectedText = extractedItems.flatMap({ $0.selectedText }).joined(separator: "\n\n")
            let urls = extractedItems.flatMap({ $0.url })

            completion(ExtractedItem(selectedText: combinedSelectedText,
                                     description: combinedDescription,
                                     url: urls.first,
                                     title: combinedTitle,
                                     image: nil))
        }
    }

    func extractImages(completion: @escaping ([UIImage]?) -> Void) {
        guard let imageExtractor = imageExtractor else {
            completion(nil)
            return
        }
        imageExtractor.extract(context: extensionContext) { extractedItems in
            guard extractedItems.count > 0 else {
                completion(nil)
                return
            }
            let images = extractedItems.flatMap({ $0.image })
            completion(images)
        }
    }
}

private protocol ExtensionContentExtractor {
    func canHandle(context: NSExtensionContext) -> Bool
    func extract(context: NSExtensionContext, completion: @escaping ([ExtractedItem]) -> Void)
}

private protocol TypeBasedExtensionContentExtractor: ExtensionContentExtractor {
    associatedtype Payload
    var acceptedType: String { get }
    func convert(payload: Payload) -> ExtractedItem?
}

private extension TypeBasedExtensionContentExtractor {
    func canHandle(context: NSExtensionContext) -> Bool {
        return !context.itemProviders(ofType: acceptedType).isEmpty
    }

    func extract(context: NSExtensionContext, completion: @escaping ([ExtractedItem]) -> Void) {
        let itemProviders = context.itemProviders(ofType: acceptedType)
        var results = [ExtractedItem]()
        guard itemProviders.count > 0 else {
            DispatchQueue.main.async {
                completion(results)
            }
            return
        }

        // There 1 or more valid item providers here, lets work through them
        let syncGroup = DispatchGroup()
        for provider in itemProviders {
            syncGroup.enter()
            // Remember, this is an async call....
            provider.loadItem(forTypeIdentifier: acceptedType, options: nil) { (payload, error) in
                let payload = payload as? Payload
                let result = payload.flatMap(self.convert(payload:))
                if let result = result {
                    results.append(result)
                }
                syncGroup.leave()
            }
        }

        // Call the completion handler after all of the provider items are loaded
        syncGroup.notify(queue: DispatchQueue.main) {
            completion(results)
        }
    }
}

private struct URLExtractor: TypeBasedExtensionContentExtractor {
    typealias Payload = URL
    let acceptedType = kUTTypeURL as String

    func convert(payload: URL) -> ExtractedItem? {
        guard !payload.isFileURL else {
            return nil
        }
        var returnedItem = ExtractedItem()
        returnedItem.url = payload
        return returnedItem
    }
}

private struct ImageExtractor: TypeBasedExtensionContentExtractor {
    typealias Payload = AnyObject
    let acceptedType = kUTTypeImage as String
    func convert(payload: AnyObject) -> ExtractedItem? {
        let loadedImage: UIImage?
        switch payload {
        case let url as URL:
            loadedImage = UIImage(contentsOfURL: url)
        case let data as Data:
            loadedImage = UIImage(data: data)
        case let image as UIImage:
            loadedImage = image
        default:
            loadedImage = nil
        }

        var returnedItem = ExtractedItem()
        returnedItem.image = loadedImage
        return returnedItem
    }
}

private struct PropertyListExtractor: TypeBasedExtensionContentExtractor {
    typealias Payload = [String: Any]
    let acceptedType = kUTTypePropertyList as String
    func convert(payload: [String: Any]) -> ExtractedItem? {
        guard let results = payload[NSExtensionJavaScriptPreprocessingResultsKey] as? [String: Any] else {
            return nil
        }

        var returnedItem = ExtractedItem()
        returnedItem.title = string(in: results, forKey: "title")
        returnedItem.selectedText = string(in: results, forKey: "selection")
        returnedItem.description = string(in: results, forKey: "description")

        if let urlString = string(in: results, forKey: "url") {
            returnedItem.url = URL(string: urlString)
        }

        return returnedItem
    }

    func string(in dictionary: [String: Any], forKey key: String) -> String? {
        guard let value = dictionary[key] as? String,
            !value.isEmpty else {
                return nil
        }
        return value
    }
}

private struct PlainTextExtractor: TypeBasedExtensionContentExtractor {
    typealias Payload = String
    let acceptedType = kUTTypePlainText as String

    func convert(payload: String) -> ExtractedItem? {
        guard !payload.isEmpty else {
            return nil
        }
        var returnedItem = ExtractedItem()
        returnedItem.selectedText = payload
        return returnedItem
    }
}

private struct SharePostExtractor: TypeBasedExtensionContentExtractor {
    typealias Payload = Data
    let acceptedType = SharePost.typeIdentifier
    func convert(payload: Data) -> ExtractedItem? {
        guard let post = SharePost(data: payload) else {
            return nil
        }

        var returnedItem = ExtractedItem()
        returnedItem.title = post.title
        returnedItem.selectedText = post.content
        returnedItem.url = post.url
        returnedItem.description = post.summary
        return returnedItem
    }
}
