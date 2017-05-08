import Foundation
import MobileCoreServices
import UIKit

/// A type that represents the information we can extract from an extension context
///
enum ExtractedShare {
    /// Some text
    case text(String)
    /// An image
    case image(UIImage)
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
        guard let extractor = extractor else {
            return
        }
        extractor.extract(context: extensionContext, completion: completion)
    }

    /// Determines if the extractor will be able to obtain valid content from
    /// the extension context.
    ///
    /// This doesn't ensure success though. It will only check that the context
    /// includes known types, but there might still be errors loading the content.
    ///
    var validContent: Bool {
        return extractor != nil
    }

}


// MARK: - Private

private extension ShareExtractor {
    var supportedExtractors: [ExtensionContentExtractor] {
        return [
            SharePostExtractor(),
            PropertyListExtractor(),
            ImageExtractor(),
            URLExtractor()
        ]
    }

    var extractor: ExtensionContentExtractor? {
        return supportedExtractors.first(where: { extractor in
            extractor.canHandle(context: extensionContext)
        })
    }
}

private protocol ExtensionContentExtractor {
    func canHandle(context: NSExtensionContext) -> Bool
    func extract(context: NSExtensionContext, completion: @escaping (ExtractedShare) -> Void)
}

private protocol TypeBasedExtensionContentExtractor: ExtensionContentExtractor {
    associatedtype Payload
    var acceptedType: String { get }
    func convert(payload: Payload) -> ExtractedShare?
}

private extension TypeBasedExtensionContentExtractor {
    func canHandle(context: NSExtensionContext) -> Bool {
        return !context.itemProviders(ofType: acceptedType).isEmpty
    }

    func extract(context: NSExtensionContext, completion: @escaping (ExtractedShare) -> Void) {
        guard let provider = context.itemProviders(ofType: acceptedType).first else {
            return
        }
        provider.loadItem(forTypeIdentifier: acceptedType, options: nil) { (payload, error) in
            guard let payload = payload as? Payload,
                let result = self.convert(payload: payload) else {
                return
            }
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
}

private struct URLExtractor: TypeBasedExtensionContentExtractor {
    typealias Payload = URL
    let acceptedType = kUTTypeURL as String

    func convert(payload: URL) -> ExtractedShare? {
        return .text(payload.absoluteString)
    }
}

private struct ImageExtractor: TypeBasedExtensionContentExtractor {
    typealias Payload = AnyObject
    let acceptedType = kUTTypeImage as String
    func convert(payload: AnyObject) -> ExtractedShare? {
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

        return loadedImage.map(ExtractedShare.image)
    }
}

private struct PropertyListExtractor: TypeBasedExtensionContentExtractor {
    typealias Payload = [String: Any]
    let acceptedType = kUTTypePropertyList as String
    func convert(payload: [String : Any]) -> ExtractedShare? {
        guard let results = payload[NSExtensionJavaScriptPreprocessingResultsKey] as? [String: Any] else {
            return nil
        }
        let selectedText = string(in: results, forKey: "selection")
        let title = string(in: results, forKey: "title")
        let url = string(in: results, forKey: "url")
        var content = ""

        let excerpt = selectedText ?? title
        if let excerpt = excerpt {
            content.append("\(excerpt)\n\n")
        }
        if let url = url {
            content.append(url)
        }
        return .text(content)
    }

    func string(in dictionary: [String: Any], forKey key: String) -> String? {
        guard let value = dictionary[key] as? String,
            !value.isEmpty else {
            return nil
        }
        return value
    }
}

private struct SharePostExtractor: TypeBasedExtensionContentExtractor {
    typealias Payload = Data
    let acceptedType = SharePost.typeIdentifier
    func convert(payload: Data) -> ExtractedShare? {
        guard let post = SharePost(data: payload) else {
            return nil
        }
        return .text(post.content)
    }
}
