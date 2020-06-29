import Foundation
import Aztec

class GutenbergCoverUploadProcessor: Processor {
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

    lazy var coverBlockProcessor = GutenbergBlockProcessor(for: CoverBlockKeys.name, replacer: { coverBlock in
        guard let mediaID = coverBlock.attributes[CoverBlockKeys.id] as? Int,
            mediaID == self.mediaUploadID else {
                return nil
        }
        var block = "<!-- \(CoverBlockKeys.name) "

        var attributes = coverBlock.attributes
        attributes[CoverBlockKeys.id] = self.serverMediaID
        attributes[CoverBlockKeys.url] = self.remoteURLString

        if let jsonData = try? JSONSerialization.data(withJSONObject: attributes, options: [.sortedKeys]),
            let jsonString = String(data: jsonData, encoding: .utf8) {
            block += jsonString
        }

        let innerProcessor = self.isVideo(attributes) ? self.videoUploadProcessor() : self.imgUploadProcessor()

        block += " -->"
        block += innerProcessor.process(coverBlock.content)
        block += "<!-- /\(CoverBlockKeys.name) -->"
        return block
    })

    func process(_ text: String) -> String {
        return coverBlockProcessor.process(text)
    }

    private func processInnerBlocks(_ outerBlock: GutenbergBlock) -> String {
        var block = "<!-- wp:cover "
        let attributes = outerBlock.attributes

        if let jsonData = try? JSONSerialization.data(withJSONObject: attributes, options: [.sortedKeys]),
            let jsonString = String(data: jsonData, encoding: .utf8) {
            block += jsonString
        }

        block += " -->"
        block += coverBlockProcessor.process(outerBlock.content)
        block += "<!-- /wp:cover -->"
        return block
    }
}

// Image Support
extension GutenbergCoverUploadProcessor {
    private struct ImgHTMLKeys {
        static let name = "div"
        static let styleComponents = "style"
        static let backgroundImage = "background-image:url"
    }

    private func imgUploadProcessor() -> HTMLProcessor {
        return HTMLProcessor(for: ImgHTMLKeys.name, replacer: { (div) in

            guard let styleAttributeValue = div.attributes[ImgHTMLKeys.styleComponents]?.value,
                case let .string(styleAttribute) = styleAttributeValue
                else {
                    return nil
            }

            let range = styleAttribute.utf16NSRange(from: styleAttribute.startIndex ..< styleAttribute.endIndex)
            let regex = self.localBackgroundImageRegex()
            let matches = regex.matches(in: styleAttribute,
                                        options: [],
                                        range: range)
            guard matches.count == 1 else {
                return nil
            }

            let style = "\(ImgHTMLKeys.backgroundImage)(\(self.remoteURLString))"
            let updatedStyleAttribute = regex.stringByReplacingMatches(in: styleAttribute,
                                                                       options: [],
                                                                       range: range,
                                                                       withTemplate: style)

            var attributes = div.attributes
            attributes.set(.string(updatedStyleAttribute), forKey: ImgHTMLKeys.styleComponents)

            let attributeSerializer = ShortcodeAttributeSerializer()
            var html = "<\(ImgHTMLKeys.name) "
            html += attributeSerializer.serialize(attributes)
            html += ">"
            html += div.content ?? ""
            html += "</\(ImgHTMLKeys.name)>"
            return html
        })
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

    private func isVideo(_ attributes: [String: Any]) -> Bool {
        guard let backgroundType = attributes[CoverBlockKeys.backgroundType] as? String else { return false }
        return backgroundType == CoverBlockKeys.videoType
    }

    private func videoUploadProcessor() -> HTMLProcessor {
        return HTMLProcessor(for: VideoHTMLKeys.name, replacer: { (video) in
            var attributes = video.attributes
            attributes.set(.string(self.remoteURLString), forKey: VideoHTMLKeys.source)

            let attributeSerializer = ShortcodeAttributeSerializer()
            var html = "<\(VideoHTMLKeys.name) "
            html += attributeSerializer.serialize(attributes)
            html += ">"
            html += video.content ?? ""
            html += "</\(VideoHTMLKeys.name)>"
            return html
        })
    }
}
