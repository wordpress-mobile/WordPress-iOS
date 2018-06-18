import Foundation
import Aztec

/**
 Manages the completion of a document upload, by replacing a placeholder attachment image with a
 link to the uploaded document.
 */
class DocumentUploadProcessor: Processor {

    private let mediaUploadID: String
    private let remoteURLString: String
    private let title: String

    private lazy var processor = HTMLProcessor(for: "img", replacer: { [mediaUploadID, remoteURLString, title] img in
        guard
            let uploadKeyValue = img.attributes[MediaAttachment.uploadKey]?.value,
            case let .string(imageUploadIdentifier) = uploadKeyValue,
            mediaUploadID == imageUploadIdentifier
        else {
            return nil
        }

        var html = "<a href=\"\(remoteURLString)\">\(title)</a><br />"
        return html
    })

    init(mediaUploadID: String, remoteURLString: String, title: String) {
        self.mediaUploadID = mediaUploadID
        self.remoteURLString = remoteURLString
        self.title = title
    }

    func process(_ text: String) -> String {
        return processor.process(text)
    }
}
