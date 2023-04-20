import Foundation
import Aztec

class GutenbergVideoPressUploadProcessor: Processor {

    let mediaUploadID: Int32
    let serverMediaID: Int
    let videoPressGUID: String

    private enum VideoPressBlockKeys: String {
        case name = "wp:videopress/video"
        case id
        case guid
        case src
    }

    init(mediaUploadID: Int32, serverMediaID: Int, videoPressGUID: String) {
        self.mediaUploadID = mediaUploadID
        self.serverMediaID = serverMediaID
        self.videoPressGUID = videoPressGUID
    }

    lazy var videoPressBlockProcessor = GutenbergBlockProcessor(for: VideoPressBlockKeys.name.rawValue, replacer: { videoPressBlock in
        guard let mediaID = videoPressBlock.attributes[VideoPressBlockKeys.id.rawValue] as? Int, mediaID == self.mediaUploadID else {
            return nil
        }
        var block = "<!-- \(VideoPressBlockKeys.name.rawValue) "
        var attributes = videoPressBlock.attributes
        attributes[VideoPressBlockKeys.id.rawValue] = self.serverMediaID
        attributes[VideoPressBlockKeys.guid.rawValue] = self.videoPressGUID
        // Removing `src` attribute if it points to a local file.
        if let srcAttribute = attributes[VideoPressBlockKeys.src.rawValue] as? String, srcAttribute.starts(with: "file:") {
            attributes.removeValue(forKey: VideoPressBlockKeys.src.rawValue)
        }
        if let jsonData = try? JSONSerialization.data(withJSONObject: attributes, options: .sortedKeys),
            let jsonString = String(data: jsonData, encoding: .utf8) {
            block += jsonString
        }
        block += " /-->"
        return block
    })

    func process(_ text: String) -> String {
        return videoPressBlockProcessor.process(text)
    }
}
