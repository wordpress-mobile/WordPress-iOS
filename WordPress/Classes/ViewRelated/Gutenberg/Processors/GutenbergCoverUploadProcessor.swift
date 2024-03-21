import Foundation
import Aztec

class GutenbergCoverUploadProcessor: GutenbergProcessor {
    public typealias InnerBlockProcessor = (String) -> String?

    private struct CoverBlockKeys {
        static let name = "wp:cover"
        static let id = "id"
        static let url = "url"
        static let backgroundType = "backgroundType"
        static let videoType = "video"
    }

    let mediaUploadID: Int32
    let remoteURLString: String
    let serverMediaID: Int

    init(mediaUploadID: Int32, serverMediaID: Int, remoteURLString: String) {
        self.mediaUploadID = mediaUploadID
        self.serverMediaID = serverMediaID
        self.remoteURLString = remoteURLString
    }

    func process(_ blocks: [GutenbergParsedBlock]) {
        blocks.filter { $0.name == "wp:cover" }.forEach { block in
            guard let mediaID = block.attributes[CoverBlockKeys.id] as? Int,
                mediaID == self.mediaUploadID else {
                    return
            }

            block.attributes[CoverBlockKeys.id] = self.serverMediaID
            block.attributes[CoverBlockKeys.url] = self.remoteURLString

            if self.isVideo(block) {
                self.processVideoTags(block)
            }
            else {
                self.processDivTags(block)
            }
        }
    }
}

// Image Support
extension GutenbergCoverUploadProcessor {
    private struct ImgHTMLKeys {
        static let name = "div"
        static let styleComponents = "style"
        static let backgroundImage = "background-image:url"
    }

    private func processDivTags(_ block: GutenbergParsedBlock) {
        let divTags = try? block.elements.select(ImgHTMLKeys.name)
        divTags?.forEach { div in
            guard let styleAttribute = try? div.attr(ImgHTMLKeys.styleComponents) else {
                return
            }

            let range = styleAttribute.utf16NSRange(from: styleAttribute.startIndex ..< styleAttribute.endIndex)
            let regex = self.localBackgroundImageRegex()
            let matches = regex.matches(in: styleAttribute,
                                        options: [],
                                        range: range)
            guard matches.count == 1 else {
                return
            }

            let style = "\(ImgHTMLKeys.backgroundImage)(\(self.remoteURLString))"
            let updatedStyleAttribute = regex.stringByReplacingMatches(in: styleAttribute,
                                                                       options: [],
                                                                       range: range,
                                                                       withTemplate: style)

            _ = try? div.attr(ImgHTMLKeys.styleComponents, updatedStyleAttribute)
        }
    }

    private func localBackgroundImageRegex() -> NSRegularExpression {
        let pattern = "background-image:[ ]?url\\(file:\\/\\/\\/.*\\)"
        return try! NSRegularExpression(pattern: pattern, options: .caseInsensitive)
    }
}

// Video Support
extension GutenbergCoverUploadProcessor {
    private struct VideoHTMLKeys {
        static let name = "video"
        static let source = "src"
    }

    private func isVideo(_ block: GutenbergParsedBlock) -> Bool {
        guard let backgroundType = block.attributes[CoverBlockKeys.backgroundType] as? String else { return false }
        return backgroundType == CoverBlockKeys.videoType
    }

    private func processVideoTags(_ block: GutenbergParsedBlock) {
        let videoTags = try? block.elements.select(VideoHTMLKeys.name)
        videoTags?.forEach { video in
            _ = try? video.attr(VideoHTMLKeys.source, self.remoteURLString)
        }
    }
}
