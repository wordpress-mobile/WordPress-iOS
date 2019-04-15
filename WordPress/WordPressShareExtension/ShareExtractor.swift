import Foundation
import MobileCoreServices
import UIKit
import ZIPFoundation

/// A type that represents the information we can extract from an extension context
///
struct ExtractedShare {
    var title: String
    var description: String
    var url: URL?
    var selectedText: String
    var importedText: String
    var images: [UIImage]

    var combinedContentHTML: String {
        var rawLink = ""
        var readOnText = ""

        if let url = url {
            rawLink = url.absoluteString.stringWithAnchoredLinks()
            let attributionText = NSLocalizedString("Read on",
                                                    comment: "In the share extension, this is the text used right before attributing a quote to a website. Example: 'Read on www.site.com'. We are looking for the 'Read on' text in this situation.")
            readOnText = "<br>— \(attributionText) \(rawLink)"
        }

        // Build the returned string by doing the following:
        //   * 1: Look for imported text.
        //   * 2: Look for selected text, if it exists put it into a blockquote.
        //   * 3: No selected text, but we have a page description...use that.
        //   * 4: No selected text, but we have a page title...use that.
        //   * Finally, default to a simple link if nothing else is found
        guard importedText.isEmpty else {
            return importedText.escapeHtmlNamedEntities()
        }

        guard selectedText.isEmpty else {
            return "<blockquote><p>\(selectedText.escapeHtmlNamedEntities())\(readOnText)</p></blockquote>"
        }

        if !description.isEmpty {
            return "<p>\(description)\(readOnText)</p>"
        } else if !title.isEmpty {
            return "<p>\(title)\(readOnText)</p>"
        } else {
            return "<p>\(rawLink)</p>"
        }
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
                let importedText = extractedTextResults?.importedText ?? ""
                let url = extractedTextResults?.url
                var returnedImages = images ?? [UIImage]()
                if let extractedImages = extractedTextResults?.images {
                    returnedImages.append(contentsOf: extractedImages)
                }

                completion(ExtractedShare(title: title,
                                          description: description,
                                          url: url,
                                          selectedText: selectedText,
                                          importedText: importedText,
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

    /// Text that was imported from another app
    ///
    var importedText: String?

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
    var images: [UIImage]?
}

private extension ShareExtractor {
    var supportedTextExtractors: [ExtensionContentExtractor] {
        return [
            SharePostExtractor(),
            ShareBlogExtractor(),
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

            let combinedTitle = extractedItems.compactMap({ $0.title }).joined(separator: " ")
            let combinedDescription = extractedItems.compactMap({ $0.description }).joined(separator: " ")
            let combinedSelectedText = extractedItems.compactMap({ $0.selectedText }).joined(separator: "\n\n")
            let combinedImportedText = extractedItems.compactMap({ $0.importedText }).joined(separator: "\n\n")
            let combinedImages = extractedItems.compactMap({ $0.images }).flatMap({ $0 })
            let urls = extractedItems.compactMap({ $0.url })

            completion(ExtractedItem(selectedText: combinedSelectedText,
                                     importedText: combinedImportedText,
                                     description: combinedDescription,
                                     url: urls.first,
                                     title: combinedTitle,
                                     images: combinedImages))
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
            let images = extractedItems.compactMap({ $0.images }).flatMap({ $0 })
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
        print(acceptedType)
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
            return processLocalFile(url: payload)
        }

        var returnedItem = ExtractedItem()
        returnedItem.url = payload

        return returnedItem
    }

    private func processLocalFile(url: URL) -> ExtractedItem? {
        switch url.pathExtension {
        case "textbundle":
            return handleTextBundle(url: url)
        case "textpack":
            return handleTextPack(url: url)
        case "text", "txt":
            return handlePlainTextFile(url: url)
        default:
            return nil
        }
    }

    private func handleTextPack(url: URL) -> ExtractedItem? {
        let fileManager = FileManager()
        guard let temporaryDirectoryURL = try? FileManager.default.url(for: .itemReplacementDirectory,
                                                                in: .userDomainMask,
                                                                appropriateFor: url,
                                                                create: true) else {
                                                                    return nil
        }

        defer {
            try? FileManager.default.removeItem(at: temporaryDirectoryURL)
        }

        let textBundleURL: URL
        do {
            try fileManager.unzipItem(at: url, to: temporaryDirectoryURL)
            let files = try fileManager.contentsOfDirectory(at: temporaryDirectoryURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            guard let unzippedBundleURL = files.first(where: { url in
                    url.pathExtension == "textbundle"
                }) else {
                return nil
            }
            textBundleURL = unzippedBundleURL
        } catch {
            DDLogError("TextPack opening failed: \(error.localizedDescription)")
            return nil
        }

        return handleTextBundle(url: textBundleURL)
    }

    private func handleTextBundle(url: URL) -> ExtractedItem? {
        var error: NSError?
        let bundleWrapper = TextBundleWrapper(contentsOf: url, options: .immediate, error: &error)

        var returnedItem = ExtractedItem()
        returnedItem.importedText = bundleWrapper.text
        var bundledImages = [UIImage]()

        bundleWrapper.assetsFileWrapper.fileWrappers?.forEach { (key: String, fileWrapper: FileWrapper) in
            guard let fileName = fileWrapper.filename,
                let fileURL = URL(string: fileName),
                let fileData = fileWrapper.regularFileContents else {
                return
            }

            switch fileURL.pathExtension.lowercased() {
            case "jpg", "jpeg", "heic":
                if let img = UIImage(data: fileData) {
                    bundledImages.append(img)
                }
            case "gif":
                print("we have a gif")
            default:
                break
            }
        }

        if bundledImages.count > 0 {
            returnedItem.images = bundledImages
        }

        return returnedItem
    }

    private func handlePlainTextFile(url: URL) -> ExtractedItem? {
        var returnedItem = ExtractedItem()
        let rawText = (try? String(contentsOf: url)) ?? ""
        returnedItem.importedText = rawText
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
        if let image = loadedImage {
            returnedItem.images = [image]
        }
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

        // Often, an attachment type _should_ have a type of "public.url" however in reality
        // the type will be "public.plain-text" which is why this Extractor is activated. As a fix,
        // let's use a data detector to determine if the payload text is a link (and check to make sure the
        // match string is the same length as the payload because the detector could find matches within
        // the selected text — we just want to make sure shared URLs are handled).
        let types: NSTextCheckingResult.CheckingType = [.link]
        let detector = try? NSDataDetector(types: types.rawValue)
        if let match = detector?.firstMatch(in: payload, options: [], range: NSMakeRange(0, payload.count)),
            match.resultType == .link,
            let url = match.url,
            url.absoluteString.count == payload.count {
            returnedItem.url = url
        } else {
            returnedItem.selectedText = payload
        }
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

private struct ShareBlogExtractor: TypeBasedExtensionContentExtractor {
    typealias Payload = Data
    let acceptedType = ShareBlog.typeIdentifier
    func convert(payload: Data) -> ExtractedItem? {
        guard let post = SharePost(data: payload) else {
            return nil
        }

        var returnedItem = ExtractedItem()
        returnedItem.title = post.title
        returnedItem.url = post.url
        returnedItem.description = post.summary

        let content: String
        if let summary = post.summary {
            content = "\(summary)\n\n"
        } else {
            content = ""
        }
        returnedItem.selectedText = content

        return returnedItem
    }
}
