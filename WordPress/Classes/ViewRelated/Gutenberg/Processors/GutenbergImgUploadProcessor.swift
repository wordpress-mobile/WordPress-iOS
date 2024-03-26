import Foundation

class GutenbergImgUploadProcessor: GutenbergProcessor {

    let mediaUploadID: Int32
    let remoteURLString: String
    let serverMediaID: Int
    static let imgClassIDPrefixAttribute = "wp-image-"

    init(mediaUploadID: Int32, serverMediaID: Int, remoteURLString: String) {
        self.mediaUploadID = mediaUploadID
        self.serverMediaID = serverMediaID
        self.remoteURLString = remoteURLString
    }

    func processImgTags(_ block: GutenbergParsedBlock) {
        let imgTags = try? block.elements.select("img")
        imgTags?.forEach { img in
            guard let imgClass = try? img.attr("class") else {
                return
            }
            let classAttributes = imgClass.components(separatedBy: " ")

            guard let imageIDAttribute = classAttributes.filter({ (value) -> Bool in
                value.hasPrefix(GutenbergImgUploadProcessor.imgClassIDPrefixAttribute)
            }).first else {
                return
            }

            let imageIDString = String(imageIDAttribute.dropFirst(GutenbergImgUploadProcessor.imgClassIDPrefixAttribute.count))
            let imgUploadID = Int32(imageIDString)

            guard imgUploadID == self.mediaUploadID else {
                return
            }

            let newImgClassAttributes = imgClass.replacingOccurrences(of: imageIDAttribute, with: GutenbergImgUploadProcessor.imgClassIDPrefixAttribute + String(self.serverMediaID))

            _ = try? img.attr("src", self.remoteURLString)
            _ = try? img.attr("class", newImgClassAttributes)
        }
    }

    func processImageBlocks(_ blocks: [GutenbergParsedBlock]) {
        blocks.filter { $0.name == "wp:image" }.forEach { block in
            guard let mediaID = block.attributes["id"] as? Int,
                mediaID == self.mediaUploadID else {
                    return
            }
            block.attributes["id"] = self.serverMediaID
            processImgTags(block)
        }
    }

    func processMediaTextBlocks(_ blocks: [GutenbergParsedBlock]) {
        blocks.filter { $0.name == "wp:media-text" }.forEach { block in
            guard let mediaID = block.attributes["mediaId"] as? Int,
                mediaID == self.mediaUploadID else {
                    return
            }
            block.attributes["mediaId"] = self.serverMediaID
            processImgTags(block)
        }
    }

    func process(_ blocks: [GutenbergParsedBlock]) {
        processImageBlocks(blocks)
        processMediaTextBlocks(blocks)
    }
}
