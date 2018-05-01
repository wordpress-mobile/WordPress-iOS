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

    private lazy var processor = HTMLProcessor(tag: "img", replacer: { [mediaUploadID, remoteURLString, title] img in
        guard
            let imageUploadIdentifier = img.attributes.named[MediaAttachment.uploadKey],
            mediaUploadID == imageUploadIdentifier
            else { return nil }

        var html = "<a href=\"\(remoteURLString)\">\(title)</a>"
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
