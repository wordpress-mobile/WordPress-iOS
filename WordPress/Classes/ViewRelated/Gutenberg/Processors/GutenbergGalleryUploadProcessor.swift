import Foundation
import Aztec

class GutenbergGalleryUploadProcessor: Processor {

    let mediaUploadID: Int
    let remoteURLString: String
    let serverMediaID: Int
    static let imgClassIDPrefixAttribute = "wp-image-"

    init(mediaUploadID: Int, serverMediaID: Int, remoteURLString: String) {
        self.mediaUploadID = mediaUploadID
        self.serverMediaID = serverMediaID
        self.remoteURLString = remoteURLString
    }

    private struct ImageKeys {
        static let name = "img"
        static let classAttributes = "class"
        static let classIDPrefix = "wp-image-"
        static let dataID = "data-id"
        static let dataFullURL = "data-full-url"
        static let dataLink = "data-link"
    }

    lazy var imgPostMediaUploadProcessor = HTMLProcessor(for: ImageKeys.name, replacer: { (img) in
        guard let imgClassAttributeValue = img.attributes[ImageKeys.classAttributes]?.value,
            case let .string(imgClass) = imgClassAttributeValue else {
                return nil
        }

        let classAttributes = imgClass.components(separatedBy: " ")

        guard let imageIDAttribute = classAttributes.filter({ (value) -> Bool in
            value.hasPrefix(GutenbergImgUploadProcessor.imgClassIDPrefixAttribute)
        }).first else {
            return nil
        }

        let imageIDString = String(imageIDAttribute.dropFirst(ImageKeys.classIDPrefix.count))
        let imgUploadID = Int(imageIDString)

        guard imgUploadID == self.mediaUploadID else {
            return nil
        }

        let newImgClassAttributes = imgClass.replacingOccurrences(of: imageIDAttribute, with: ImageKeys.classIDPrefix + String(self.serverMediaID))

        var attributes = img.attributes
        attributes.set(.string(self.remoteURLString), forKey: "src")
        attributes.set(.string(newImgClassAttributes), forKey: "class")
        attributes.set(.string("\(self.serverMediaID)"), forKey: ImageKeys.dataID)
        attributes.set(.string(self.remoteURLString), forKey: ImageKeys.dataFullURL)
        if attributes.contains(where: { $0.key == ImageKeys.dataLink } ) {
            attributes.set(.string(self.remoteURLString), forKey: ImageKeys.dataLink)
        }

        var html = "<\(ImageKeys.name) "
        let attributeSerializer = ShortcodeAttributeSerializer()
        html += attributeSerializer.serialize(attributes)
        html += " />"
        return html
    })

    private struct LinkKeys {
        static let name = "a"
    }

    lazy var linkPostMediaUploadProcessor = HTMLProcessor(for: LinkKeys.name, replacer: { (link) in

        guard let linkOriginalContent = link.content else {
            return nil
        }

        let linkUpdatedContent = self.imgPostMediaUploadProcessor.process(linkOriginalContent)

        guard linkUpdatedContent != linkOriginalContent else {
            return nil
        }

        var attributes = link.attributes
        attributes.set(.string(self.remoteURLString), forKey: "href")

        var html = "<\(LinkKeys.name) "
        let attributeSerializer = ShortcodeAttributeSerializer()
        html += attributeSerializer.serialize(attributes)
        html += " >"
        html += linkUpdatedContent
        html += "</\(LinkKeys.name)>"
        return html
    })

    private struct GalleryBlockKeys {
        static let name = "wp:gallery"
        static let ids = "ids"
        static let linkTo = "linkTo"
    }

    lazy var galleryBlockProcessor = GutenbergBlockProcessor(for: GalleryBlockKeys.name, replacer: { block in
        guard var ids = block.attributes[GalleryBlockKeys.ids] as? [String],
            ids.contains(String(self.mediaUploadID)) else {
                return nil
        }
        var updatedBlock = "<!-- \(GalleryBlockKeys.name) "
        var attributes = block.attributes
        if let index = ids.firstIndex(of: String(self.mediaUploadID) ) {
            ids[index] = String(self.serverMediaID)
        }
        attributes[GalleryBlockKeys.ids] = ids;
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: attributes, options: .sortedKeys),
            let jsonString = String(data: jsonData, encoding: .utf8) {
            updatedBlock += jsonString
        }
        updatedBlock += " -->"
        if block.attributes[GalleryBlockKeys.linkTo] == nil {
            updatedBlock += self.imgPostMediaUploadProcessor.process(block.content)
        } else {
            updatedBlock += self.linkPostMediaUploadProcessor.process(block.content)
        }
        updatedBlock += "<!-- /\(GalleryBlockKeys.name) -->"
        return updatedBlock
    })

    func process(_ text: String) -> String {
        let result = galleryBlockProcessor.process(text)
        return result
    }
}
